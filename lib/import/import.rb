# frozen_string_literal: true

require_relative 'csv_loader'
require_relative 'pluraliser'
require_relative 'bibliography_loader'
require_relative 'source_saver'
# require "#{Rails.root}/config/environment"

module Import
  # Class which handles importing the dictionary CSV.
  class ImportHelper
    def initialize(bibliography_data = nil, error_reporter = ErrorReporter.new)
      unless bibliography_data
        bibliography_data = BibliographyLoader.new(error_reporter).load
      end

      # Map of word_string->[Definitions]
      @word_definitions = {}

      # Map of word_string -> Word(obj)
      @word_objs = {}

      # Map of Definition->see_also[]
      # Used to create related_definition associations
      @relateds = {}

      # Data including source materials and regex to match source refs
      @bibliography_data = bibliography_data

      @error_reporter = error_reporter

      # Map of source_ref : Source(obj.)
      @all_sources = {}

      @source_saver = SourceSaver.new(error_reporter)
    end

    # Top level method which runs the import
    def import(filename = 'yhd.csv')
      # Load CSV rows
      puts 'Attempting to load CSV...'
      data = CsvLoader.load_csv filename

      # Error if no data
      unless data
        puts 'ERROR: unable to load data from CSV. Terminating.'
        return
      end

      # Extract headers (first row)
      headers = data[0]

      puts 'Normalising header names...'
      norm_headers = normalise_headers headers

      # Define data rows as the rest of the CSV
      row_range = 1..data.size

      # Get data from each row (process it line at a time)
      puts 'Loading data...'
      load_data_from_rows(norm_headers, data[row_range])

      puts 'Creating relationships between definitions...'
      create_definition_associations

      puts 'Done!'

      @error_reporter.print
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

      norm_headers
    end

    # Normalise a single header
    def normalise_header(header_name)
      # Set a non-empty value of header if its missing
      header_name ||= 'empty'

      # Lower case header name
      header_name = header_name.downcase

      # Try normalising as if it was an alt. spelling header
      normalised_header ||= normalise_alt_spelling(header_name)

      # Try normalising as if it was a source-related header
      normalised_header ||= normalise_source_header(header_name)

      # If nothing matched thus far, use header_name as is
      normalised_header || header_name
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
      # Hash of field values
      fields = {}

      # List of alternate spellings found in current row
      alt_spellings = []

      # Related words for current row
      see_also = []

      # List of hashes of source data for current row
      sources = []

      # Loop through the cells in the row
      row.each_with_index do |field_value, col_index|
        # Skip empty cells
        next unless field_value

        # Remove leading/trailing whitespace from field value
        field_value = field_value.strip

        # Get current header
        header = headers[col_index]

        if header.start_with? 'headword'
          headword_data = headword_data field_value
          fields = fields.merge headword_data
          next
        end

        if header.start_with? 'altspelling'
          alt_spellings << field_value
          next
        end

        if header.start_with? 'source'
          match = self.class.source_header_regex.match header

          # Get source number i.e. source1
          source_num = match[1].to_i - 1 # Subtract 1 since CSV vals are 1-based, and arrays are 0-based

          # Ref/original_ref/date/place
          source_component = match[2]

          # Find or create source record for current source
          current_source = sources[source_num] ||= {}

          # Add current field to source obj
          current_source[source_component.to_sym] = field_value
          current_source[:source_num] = source_num
          next
        end

        if header == 'see also'
          current_see_also = see_also_from_string field_value
          see_also += current_see_also
          next
        end

        # No match, so just add as is
        fields[header.to_sym] = field_value
      end

      # Fields that are handled specially
      special_fields = { alt_spellings: alt_spellings, see_also: see_also, sources: sources }

      # Add special fields to all others
      all_fields = special_fields.merge fields

      all_fields
    end

    # Save the data from the rows, incl. words
    def save_row_data(data)
      word = data[:word]

      # Attempt to retrieve Word obj & save to DB
      word_obj = @word_objs[word]

      # Create new word obj. if not found
      unless word_obj
        # TODO: Could use 'new' instead of 'create' here and batch save at end
        word_obj = Word.where(text: word).first_or_create
        @word_objs[word] = word_obj
        puts "Error with word '#{word}': #{word_obj.errors.full_messages}" if word_obj.errors.present?
      end

      # TODO: Could use 'new' instead of 'create' here and batch save at end
      # Create definition obj & save

      existing_defs = word_obj.definitions
      def_index = data[:index]
      definition = existing_defs[def_index] if existing_defs.size >= (def_index - 1)
      definition = existing_defs.create if definition.nil?
      definition.update(discussion: data[:discussion], text: data[:definition])

      # Report any errors with save
      puts "Error with definition '#{word.downcase}': #{definition.errors.full_messages}" if definition.errors.present?

      # Create alt_spellings
      data[:alt_spellings].each do |alt|
        alt_obj = definition.alt_spellings.where(text: alt).first_or_create
        puts "Error with alternate spelling '#{alt}': #{alt_obj.errors.full_messages}" if alt_obj.errors.present?
      end

      # Save source data
      @source_saver.save_sources(definition, data[:sources], @bibliography_data)

      # Some data can't be saved now since it relies on all definitions and words being saved first
      # Add this data to the relevant instance vars. for later
      record_data_for_later_saving data, definition
    end

    # Add data to instance vars which will be saved in a batch at the end of processing all rows
    def record_data_for_later_saving(data, definition)
      word = data[:word]
      word_index = data[:index]

      # Add current definition's see_also list to map for processing later
      @relateds[definition] = data[:see_also]

      # Add definition to map of word obj. -> definition objects.
      # This mapping will be used to link all related definitions after they've all been created
      @word_definitions[word.downcase] ||= []
      @word_definitions[word.downcase][word_index] = definition
    end

    # Splits 'see also' field by semi-colon, returns all resulting terms
    def see_also_from_string(string)
      see_also = []
      string.split(';').each do |see_also_word|
        see_also << see_also_word.downcase.strip
      end

      see_also
    end

    # Create the associations between definitons (see_also in CSV)
    def create_definition_associations
      # TODO: make sure functionality for extracting word + index is extracted and shared
      # Loop through map of defs to related words and create the association
      @relateds.each do |definition, see_also_records|
        see_also_records.each do |see_also_word|
          headword_data = headword_data see_also_word
          word = headword_data[:word]
          word_index = headword_data[:index]

          # Get the definition for the word and word index
          related_def = @word_definitions.dig(word.downcase, word_index)
          unless related_def
            # Missing related definition - report error, skip
            @error_reporter.report_error(definition.word.text, 
              "'see_also' word not found: #{see_also_word}",
              'error'
            )
            next
          end

          # TODO: Could use 'new' instead of 'create' here and batch save at end
          # Add association to related def and report errors
          relation =  DefinitionRelation
                      .where(
                        definition: definition,
                        related_definition: related_def,
                        relation_type: 'see_also'
                      )
                      .first_or_create

          if relation.errors.present?
            error_reporter.report_error word,
                                        "Error with def relation '#{word.downcase}': #{relation.errors.full_messages}",
                                        'error'
          end
        end
      end
    end

    # Parses a headword and its index (number in brackets from CSV) and returns both in hash
    def headword_data(text)
      match = self.class.headword_regex.match text

      # Error message if headword doesn't match format
      unless match
        puts "ERROR: Can't match headword in '#{text}'"
        return nil
      end

      # Extract actual word
      word = match[1].strip

      # Create hash of results (default index of 0)
      result = { word: word, index: 0 }

      # Overwrite index if one provided
      if match[2]
        result[:index] = match[2].to_i - 1 # CSV uses 1-indexing so we subtract 1
      end

      # example result: {word: 'example', index: 0}
      result
    end

    # Normalise a single alt spelling header
    def normalise_alt_spelling(header_name)
      # Run alt spelling regex against header
      spell_match = self.class.alt_spelling_header_regex.match header_name
      if spell_match
        # Set header name as AltSpelling# where # is num
        norm_header_name = 'altspelling' + spell_match[1]
        return norm_header_name
      end
      nil
    end

    # Normalise a source header field
    def normalise_source_header(header_name)
      # Run regex to see if it matches expected format
      source_match = self.class.source_header_regex.match header_name

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
      nil
    end

    # Matches an alt-spelling header (e.g. alt spelling 3), capturing the number in capture group 1
    def self.alt_spelling_header_regex
      /alt\s?spelling\s?(\d+)/
    end

    # Matches a source-related header, such as 'source 1 place' or 'source 2 ref'
    # Group 1: source number e.g. 1 or 2
    # Group 2: source part (ref, place or date.
    # If the source part is missing, the header refers to George's original reference, which we refer to in the code as 'original_ref')
    # Since archival ref == ref, the regex includes a non-capturing group to ignore archival and just capture ref in group 2
    def self.source_header_regex
      /source\s?(\d+)\s?(?:archival)?\s?(\w+)*/
    end

    # Matches words of the format  'ale-taster (2)'
    # Group 1: word e.g. 'ale-taster'
    # Group 2: word index e.g. 2
    def self.headword_regex
      /([a-zA-Z\-\s]+)\s*(?:\((\d*)\))?/
    end
  end
end
