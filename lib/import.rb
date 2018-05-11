# frozen_string_literal: true

require 'csv'
require 'find'
require "#{Rails.root}/config/environment"

module Import

  # Class which handles importing the dictionary CSV.
  class ImportHelper
    def initialize
      # Map of word_string->[Definitions]
      @word_definitions = {}

      # Map of word_string -> Word(obj)
      @word_objs = {}

      # Map of Definition->see_also[]
      # Used to create related_definition associations
      @relateds = {}

      # Map of source_material_original_ref -> SourceMaterial
      @source_materials = {}

      # Map of place_name -> Place
      @places = {}

      # Map of Definition -> DefinitionSource[]
      @definition_sources = {}

      # Map of source_ref : Source(obj.)
      @all_sources = {}
    end

    # Top level method which runs the import
    def import
      # Load CSV rows
      puts 'Attempting to load CSV...'
      data = load_csv

      # Error if no data
      unless data
        puts 'ERROR: unable to load data from CSV. Terminating.'
        return
      end

      # Extract headers (first row)
      headers = data[0]

      # Array to hold normalised versions of the headers
      puts 'Normalising header names...'
      norm_headers = normalise_headers headers

      # Define data rows as the rest of the CSV
      row_range = 1..data.size

      puts 'Loading data...'
      load_data_from_rows(norm_headers, data[row_range])

      puts 'Creating relationships between definitions...'
      create_definition_associations

      puts 'Creating source materials & places (be patient)...'
      create_source_material_and_place_objects

      puts 'Creating relationships between definitions and sources (be patient)...'
      create_definition_source_associations

      puts 'Done!'
    end

    # Normalise the headers, which may have slightly varying names
    # e.g. source1 ref, source 1 ref and source 1 archival ref are all equiv.
    def normalise_headers(headers)
      norm_headers = []

      headers.each_with_index do |header_name, i|
        # Process the current header
        normalised_header = normalise_header header_name

        # Add header name to index of normalised header names
        norm_headers[i] = normalised_header
      end

      return norm_headers
    end

    # Normalise a single header
    def normalise_header(header_name)
      # Set a non-empty value of header if its missing
      header_name ||= 'empty'

      # Lower case header name
      header_name = header_name.downcase

      # Remove byte order mark (Excel adds this to the start of CSVs)
      header_name = header_name[1..-1] if header_name.start_with? "\xEF\xBB\xBF"

      # Try normalising as if it was an alt. spelling header
      normalised_header ||= normalise_alt_spelling(header_name)

      # Try normalising as if it was a source-related header
      normalised_header ||= normalise_source_header(header_name)

      # If nothing matched thus far, use header_name as is
      return normalised_header || header_name
    end

    # Loop through the rows, extract data from each and save it
    def load_data_from_rows(headers, data)
      num_rows = data.size
      data.each_with_index do |row, i|
        puts "\tLoading row #{i + 1}/#{num_rows}"

        # Get row data
        row_data = load_row_data(headers, row)

        # Move onto next row if no word found
        next unless row_data&.dig(:word)

        # Save data
        save_row_data row_data
      end
    end

    # Loop through the fields in a row, extract the data, and return in a single hash
    def load_row_data(headers, row)
      fields = {}
      alt_spellings = []
      see_also = []
      sources = []

      # Loop through the cells in the row
      row.each_with_index do |field_value, col_index|
        # Skip empty cells
        next unless field_value

        field_value = field_value.strip

        header = headers[col_index]

        if header.start_with? 'headword'
          headword_data = get_headword_data field_value
          fields = fields.merge headword_data
          next
        end

        if header.start_with? 'altspelling'
          alt_spellings << field_value
          next
        end

        if header.start_with? 'source'
          match = source_header_regex.match header

          # Get source number i.e. source1
          source_num = match[1].to_i - 1 # Subtract 1 since CSV vals are 1-based, and arrays are 0-based

          # Ref/original_ref/date/place
          source_component = match[2]

          # Find or create source record for current source
          current_source = sources[source_num] ||= {}

          # Add current field to source obj
          current_source[source_component] = field_value
          next
        end

        if header == 'see also'
          # Splits 'see also' field by semi-colon, adds all resulting terms to see_also array
          see_also = field_value.split(';')
          next
        end

        # No match, so just add as is
        fields[header.to_sym] = field_value
      end

      # Fields that are handled specially
      special_fields = { alt_spellings: alt_spellings, see_also: see_also, sources: sources }

      # Add special fields to all others
      all_fields = special_fields.merge fields

      return all_fields
    end

    # Save the data from the rows, incl. words, 
    def save_row_data(data)
      word = data[:word]

      # Attempt to retrieve Word obj & save to DB
      word_obj = @word_objs[word]

      # Create new word obj. if not found
      unless word_obj
        # TODO: Could use 'new' instead of 'create' here and batch save at end
        word_obj = Word.create text: word
        @word_objs[word] = word_obj
        puts word_obj.errors.full_messages
      end

      # TODO: Could use 'new' instead of 'create' here and batch save at end
      # Create definition obj & save
      definition = word_obj.definitions.create text: data[:definition],
                                               discussion: data[:discussion]

      # Report any errors with save
      puts definition.errors.full_messages

      # Create alt_spellings
      data[:alt_spellings].each do |alt|
        alt_obj = definition.alt_spellings.create text: alt
        puts alt_obj.errors.full_messages
      end

      # Some data can't be saved now since it relies on all definitions and words being saved first
      # Add this data to the relevant instance vars.
      record_data_for_later_saving data, definition
    end

    # Add data to instance vars which will be saved in a batch at the end of processing all rows
    def record_data_for_later_saving(data, definition)
      word = data[:word]
      word_index = data[:word_index]

      # Add current definition's see_also list to map for processing later
      @relateds[definition] = data[:see_also]

      # Add definition to map of word obj. -> definition objects.
      # This mapping will be used to link all related definitions after they've all been created
      @word_definitions[word] ||= []
      @word_definitions[word][word_index] = definition

      # Add sources from row to collection of all sources
      add_current_row_sources_to_all_sources data[:sources]

      # Add sources to map of definition to sources
      @definition_sources[definition] = data[:sources]
    end

    # Create the associates between definitions and their sources, and save them to the DB
    def create_definition_source_associations
      @definition_sources.each do |definition, sources|
        sources.each do |source|
          # Skip empty sources
          next unless source

          # Get source ref
          ref = source['orig_reference']

          # Retrieve source DB object for the ref
          source_material = @source_materials[ref]

          # Retrieve the place defined for the source
          place_name = source['place']
          place = @places[place_name.downcase] if place_name

          # Retrieve date for source
          date = source['date']

          # Create & save DefinitionSource association & report errors
          def_source = definition.definition_sources.create source_material: source_material, place: place, date: date
          puts def_source.errors.full_messages
        end
      end
    end

    # Create the source material and place objects, and save them to DB
    def create_source_material_and_place_objects
      # Loop through source data, and create DB object for each
      @all_sources.each do |orig_ref, source|
        # Get place name associated with source instance
        place_name = source['place']

        # If a place is defined for the source
        if place_name&.downcase&.!= 'np'
          place = @places[place_name.downcase]
          
          # Place not yet saved:
          unless place
            # TODO: Could use 'new' instead of 'create' here and batch save at end
            place = Place.create name: place_name
            place.save
            
            # Add to map of place_name -> Places
            @places[place_name.downcase] = place
            
            # Report errors
            puts place.errors.full_messages
          end
        end
        
        # Retrieve existing SourceMaterial obj, save new one if it doesn't exist
        next if @source_materials[orig_ref]
        # TODO: Could use 'new' instead of 'create' here and batch save at end
        sm = SourceMaterial.create original_ref: orig_ref, ref: source['ref']

        # Report errors
        puts sm.errors.full_messages

        # Add new obj to map of sources
        @source_materials[orig_ref] = sm
      end
    end

    # Create the associations between definitons (see_also in CSV)
    def create_definition_associations
      # Loop through map of defs to related words and create the association
      @relateds.each do |definition, see_also_records|
        see_also_records.each do |see_also_word|
          # Run regex on see_also word to get word and index
          match = headword_regex.match see_also_word

          word = match[1]
          word_index = 0

          # Check for a word index in brackets e.g. example(2)
          if match[2]
            word_index = match[2].to_i - 1 # CSV uses 1-indexing so we subtract 1
          end

          # Get the definition for the word and word index
          related_def = @word_definitions.dig(word, word_index)

          # Skip a missing definition
          next unless related_def

          # TODO: Could use 'new' instead of 'create' here and batch save at end
          # Add association to related def and report errors
          relation = DefinitionRelation.create definition: definition,
                                               related_definition: related_def,
                                               relation_type: 'see_also'
          puts relation.errors.full_messages
        end
      end
    end

    # Take the sources from a single row, and add them to a list of all sources (from whole CSV)
    def add_current_row_sources_to_all_sources(sources)
      sources.each do |source|
        # Skip empty sources (for when CSV contains an empty source in between others)
        next unless source

        # Extract source data into vars
        source_id = source['orig_reference']

        # Attempt to retrieve an existing source object
        source_record = @all_sources[source_id]

        # If there's already an existing source record for this source, add the word to its list of words
        next if source_record
        # Instantiate the source record
        source_record = source.except 'headword'
        @all_sources[source_id] = source_record
      end
    end

    # Parses a headword and its index (number in brackets from CSV) and returns both in hash
    def get_headword_data(text)
      match = headword_regex.match text

      # Error message if headword doesn't match format
      unless match
        puts "ERROR: Can't match headword in '#{text}'"
        return nil
      end

      # Create hash of results (default index of 0)
      result = { word: match[1], word_index: 0 }

      # Overwrite index if one provided
      if match[2]
        result['index'] = match[2].to_i - 1 # CSV uses 1-indexing so we subtract 1
      end

      # example result: {word: 'example', index: 0}
      return result
    end

    # Normalise a single alt spelling header
    def normalise_alt_spelling(header_name)
      # Run alt spelling regex against header
      spell_match = alt_spelling_header_regex.match header_name
      if spell_match
        # Set header name as AltSpelling# where # is num
        norm_header_name = 'altspelling' + spell_match[1]
        return norm_header_name
      end
      return nil
    end

    # Normalise a source header field
    def normalise_source_header(header_name)
      # Run regex to see if it matches expected format
      source_match = source_header_regex.match header_name
      
      if source_match
        # Set header name as source#part where:
        #   # is num
        #   part is ref, date, place or orig_reference
        norm_header_name = 'source' + source_match[1]

        # Add last part of source string (date, place, ref) to header if available
        # Default is orig_reference
        suffix = source_match[2] || 'orig_reference'
        norm_header_name += suffix

        return norm_header_name
      end
      return nil
    end

    # Locate the CSV in the project directory and read it
    def load_csv
      filename = 'yhd.csv'

      # Regex to match the filename at the end of the current path
      csv_file_regex = /.*#{Regexp.quote(filename)}$/

      puts "Searching current directory and parent directories for #{filename}..."

      # Go two dirs up and search for the file in all subdirs
      Find.find(__dir__ + '/../..') do |path|
        # Check if path matches file
        if csv_file_regex.match?(path)
          puts "\tFound yhd.csv at #{path}. Reading..."
          return CSV.read(path)\
        end
      end
      puts "ERROR: Couldn't find #{filename} anywhere."
    end

    # Matches an alt-spelling header, capturing the number in group 1
    def alt_spelling_header_regex
      /alt\s?spelling\s?(\d+)/
    end

    # Matches a source-related header, such as 'source 1 place' or 'source 2 ref'
    # Group 1: source number e.g. 1 or 2
    # Group 2: source part (ref, place or date. 
    # If the source part is missing, the header refers to George's original reference, which we refer to in the code as 'original_ref')
    # Since archival ref == ref, the regex includes a non-capturing group to ignore archival and just capture ref in group 2
    def source_header_regex
      /source\s?(\d+)\s?(?:archival)?\s?(\w+)*/
    end

    # Matches words of the format  'ale-taster (2)'
    # Group 1: word e.g. 'ale-taster'
    # Group 2: word index e.g. 2
    def headword_regex
      /([a-zA-Z\-\s]+)\s*(?:\((\d*)\))?/
    end
  end
end
