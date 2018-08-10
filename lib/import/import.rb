# frozen_string_literal: true

require_relative 'csv_loader'
require_relative 'pluraliser'
require_relative 'bibliography_loader'
require_relative 'date_extractor'
# require "#{Rails.root}/config/environment"

module Import
  # Class which handles importing the dictionary CSV.
  class ImportHelper
    def initialize
      # Map of word_string->[Definitions]
      @word_definitions = {}

      # Map of word_string -> Word(obj)
      @word_objs = {}

      # List of processing errors
      @errors = []

      # Map of Definition->see_also[]
      # Used to create related_definition associations
      @relateds = {}

      # Data including source materials and regex to match source refs
      @bibliography_data = BibliographyLoader.new.load

      # Map of place_name -> Place
      @places = {}

      # Map of source_ref : Source(obj.)
      @all_sources = {}
    end

    # Top level method which runs the import
    def import
      # Load CSV rows
      puts 'Attempting to load CSV...'
      data = CsvLoader.load_csv 'yhd.csv'

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

      puts 'Loading data...'
      load_data_from_rows(norm_headers, data[row_range])

      puts 'Creating relationships between definitions...'
      create_definition_associations

      puts 'Done!'

      @errors.each do |error|
        printf  "%-7s %-20s %s \n",
                error[:type].upcase,
                error[:word],
                error[:message]
      end
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
      save_sources(definition, data[:sources])

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

    def save_sources(definition, sources)
      # Remove existing source references for the current def.
      SourceReference.where(definition: definition).destroy_all

      source_material_refs = Hash.new { |h, k| h[k] = [] }

      # Save each source otherwise
      sources.each_with_index do |source, index|
        definition = definition

        if source.nil?
          report_error  definition,
                        "Source #{index+1}: Source is missing - should move subsequent sources to fill missing source.",
                        'error'
          next
        end

        source_ref_string = source[:orig_reference]

        # No ref found in the source data
        unless source_ref_string && self.class.source_ref_regex.match?(source_ref_string)
          report_error  definition,
                        "Source #{source[:source_number]}: Source reference '#{source_ref_string}' doesn't match expected format. Skipping.",
                        'error'
          return []
        end

        # Run regex to match components of the source reference string
        source_reference_match = @bibliography_data[:reference_regex].match source_ref_string

        unless source_reference_match
          report_error  definition,
                        "Source #{source[:source_number]}: No source record in bibliography matched for #{source_ref_string}",
                        'error'
          return []
        end

        # Extract the reference from the regex match
        source_material_reference = source_reference_match[1]

        unless source_material_reference
          # TODO: error, no source reference found in source string
        end

        # Retrieve the corresponding source material
        source_materials = @bibliography_data[:source_materials][source_material_reference.downcase] || []

        # FIXME: this next error check was moved, might not make sense here
        unless source_materials.any?
          report_error  definition,
                        "Source #{source[:source_number]}: No source material loaded from bibliography for #{source_material_reference}",
                        'error'
        end

        source_materials.each do |sm|
          source_material_refs[sm] << source
        end
      end

      source_material_refs.each do |source_material, sources|
        source_reference_obj = SourceReference.create definition: definition, source_material: source_material

        existing_excerpts = []

        # TODO: need to check if each excerpt is the same as one that's already been created, and re-use that if so
        sources.each do |source_hash|
          source_ref_string = source_hash[:orig_reference]

          # Run regex to match components of the source reference string
          source_reference_match = @bibliography_data[:reference_regex].match source_ref_string

          # Extract the reference to the excerpt
          # (volume and/or page number, or arch. ref)
          preset_archival_ref = @bibliography_data[:archival_refs][source_ref_string.downcase]
          excerpt_reference = if preset_archival_ref&.present?
                                preset_archival_ref
                              else
                                source_reference_match[2]
                              end

          next if existing_excerpts.include? excerpt_reference
          existing_excerpts << excerpt_reference

          # save_source(definition, source, index+1) unless source.nil?
          save_source_excerpts(source_hash[:source_number], source_material, excerpt_reference, source_reference_obj)

          date_string = source_hash[:date]
          save_dates(source_hash[:source_number], date_string, source_reference_obj)

          # Get place name associated with source instance
          places_string = source_hash[:place]
          save_places(source_hash[:source_number], places_string, source_reference_obj)
        end
      end
    end

    # Matches the source reference, and retrieves the relevant source materials
    # for that reference. The sub-reference is parsed, and a SourceReference &
    # SourceExcerpt objects created.
    def handle_source_ref_related_saves(source_number, source_ref_string, definition)
      definition = definition

      # No ref found in the source data
      unless source_ref_string && self.class.source_ref_regex.match?(source_ref_string)
        report_error  definition,
                      "Source #{source_number}: Source reference '#{source_ref_string}' doesn't match expected format. Skipping.",
                      'error'
        return []
      end

      # Run regex to match components of the source reference string
      source_reference_match = @bibliography_data[:reference_regex].match source_ref_string

      unless source_reference_match
        report_error  definition,
                      "Source #{source_number}: No source record in bibliography matched for #{source_ref_string}",
                      'error'
        return []
      end

      # Extract the reference from the regex match
      source_material_reference = source_reference_match[1]

      unless source_material_reference
        # TODO: error, no source reference found in source string
      end

      # Retrieve the corresponding source material
      source_materials = @bibliography_data[:source_materials][source_material_reference.downcase] || []

      unless source_materials.any?
        report_error  definition,
                      "Source #{source_number}: No source material loaded from bibliography for #{source_material_reference}",
                      'error'
      end

      # Extract the reference to the excerpt
      # (volume and/or page number, or arch. ref)
      preset_archival_ref = @bibliography_data[:archival_refs][source_ref_string.downcase]
      excerpt_reference = if preset_archival_ref&.present?
                            preset_archival_ref
                          else
                            source_reference_match[2]
                          end

      source_references = []
      source_materials.each do |source_material|
        # save_source(definition, source, index+1) unless source.nil?
        source_reference_obj = SourceReference.create definition: definition, source_material: source_material
        save_source_excerpts(source_number, source_material, excerpt_reference, source_reference_obj)
        source_references << source_reference_obj
      end
      source_references
    end

    def save_dates(source_number, date_string, source_reference)
      return if DateExtractor.nd_regex.match? date_string

      # Check for date, attempt to get date from field if match
      # TODO: handle date_string being nil, empty
      # TODO: need to track which dates match the above regexes but not the general one, and update to match
      dates = DateExtractor.get_dates date_string
      # TODO: need to report errors if dates.failures is not empty, one for each

      if dates.empty?
        report_error  source_reference.definition,
                      "Source #{source_number}: Couldn't extract dates from '#{date_string}' - doesn't match expected format, fields probably ordered wrong.",
                      'error'
      end

      dates.each do |date|
        # TODO: add all model save errors to errors output
        source_date = source_reference.source_dates.where(date).first_or_create
        puts "Error with source date '#{alt}': #{source_date.errors.full_messages}" if source_date.errors.present?
      end
    end

    def save_places(source_number, places_string, source_reference)
      # TODO: check place name doesn't match other field formats
      # TODO: warn on any other seperators: 'and', '&', ','

      return if places_string&.downcase&.== 'np'

      unless places_string
        report_error  source_reference.definition,
                      "Source #{source_number}: No place name included for source. Use 'np' to specify no associated place.",
                      'warn'
        return
      end

      places_strings = places_string.split ';'
      places_strings.each do |place_name|
        unless ImportHelper.place_name_regex.match? place_name
          report_error  source_reference.definition,
                        "Source #{source_number}: Invalid place name: #{place_name}. Skipping.",
                        'error'
          next
        end

        # If a place is defined for the source
        place = @places[place_name.downcase]

        # Place not yet saved:
        unless place
          # TODO: Could use 'new' instead of 'create' here and batch save at end
          place = Place.where(name: place_name.strip).first_or_create

          # Add to map of place_name -> Places
          @places[place_name.downcase] = place

          # Report errors
          puts "Error with place '#{place_name.downcase}': #{place.errors.full_messages}" if place.errors.present?
        end

        # TODO: need to use link table here if not implicity done?
        source_reference.places << place
      end
    end

    def save_source_excerpts(source_number, source_material, excerpt_reference, source_reference)
      definition = source_reference.definition

      # Create excerpt record for book/pub/archival source types
      case source_material.source_type
      when 'book'
        # TODO: extract volume or page numbers here
        page_regex =
          %r/((?:[\dcxlijv]{0,6}[-, ]?)*)([n])?(?:\/((?:[\dcxlijv]+n?[-, ]*)+))?/

        match = page_regex.match excerpt_reference

        unless match
          report_error  definition,
                        "Source #{source_number}: Valid page/volume number not found for source reference #{excerpt_reference}",
                        'error'
        end

        is_note = !!match[2]

        # TODO: report error if volumes[:error] / pages[:error]
        volumes_str = match[1]
        volumes = Pluraliser.pluralise volumes_str
        volume_ranges = volumes&.dig(:ranges)

        pages_str = match[3]
        pages = Pluraliser.pluralise pages_str
        page_ranges = pages&.dig(:ranges)

        if page_ranges.size > 1 &&
           volume_ranges.size > 1
          report_error definition, 'Multiple volumes and pages specified for a single reference', 'error'
          return
        end

        # TODO: should the excerpt be saved if there are no pages or volumes? The source reference already tracks the fact it's mentioned
        page_ranges << nil if page_ranges.empty?
        volume_ranges << nil if volume_ranges.empty?

        volume_ranges.each do |vol_range|
          page_ranges.each do |page_range|
            excerpt = SourceExcerpt.new source_reference: source_reference,
                                        note: is_note

            if page_range
              excerpt.page_start = page_range[:start_num]
              excerpt.page_end = page_range[:end_num]
            end

            if vol_range
              excerpt.volume_start = vol_range[:start_num]
              excerpt.volume_end = vol_range[:end_num]
            end
            # FIXME: errors on following save?
            excerpt.save
          end
        end

      when 'archival'
        # TODO: extract archival sub-reference here
        sub_reference_regex = %r{^\/?(.*|[\d,-]+)$}
        match = sub_reference_regex.match excerpt_reference

        sub_reference = nil
        if match
          sub_reference = match[1]
        else
          report_error definition, "Invalid archival excerpt reference - '#{excerpt_reference}'. Using anyway, but check. Expected format is source_reference/excerpt_reference (with slash) e.g. BIA/3/4/2.", 'warn'
          sub_reference = excerpt_reference
        end

        # page_regex_match = ImportHelper.archival_pages_regex.match sub_reference
        SourceExcerpt.where(
          source_reference: source_reference,
          archival_ref: sub_reference
        )
        .first_or_create

      else
        report_error definition, "Unknown source type: #{source_material.source_type}", 'error'
      end
    end

    def see_also_from_string(string)
      # Splits 'see also' field by semi-colon, adds all resulting terms to see_also array
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
            report_error(definition, "'see_also' word not found: #{see_also_word}", 'error')
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

          puts "Error with def relation '#{word.downcase}': #{relation.errors.full_messages}" if relation.errors.present?
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

    def report_error(definition, message, type)
      return if type.nil?
      @errors << {
        word: definition.word.text, definition: definition,
        message: message, type: type
      }
    end

    # Matches an alt-spelling header, capturing the number in group 1
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

    # TODO: this method was declared as well as the one below with same name. Check still works with this commented out.
    # def self.source_ref_regex
    #   %r{\w+\/\d+}
    # end

    # Regular date - 1805
    # Circa dates - c. 1805
    # Unknown date with range - nd [1805-1905]
    # Date range - 1805-1905 or 1805-6 or 1805-10
    # Multiple dates - 1805, 1806 or 1805 1806 1807-8 (spaces vs commas)
    # Decade - 1430s
    # Circa range - c.1300-1350

    # ^\d{4}$  // Regular date
    # ^c\.\d{4}$   // c.date
    # ^nd\s*\[.*\]$   // Estimates, need to process contained date as a regular date and set flag to estimate. Ranges or c.dates
    # ^(\d{4})-(\d+)$   // Ranges. Need to get length of second group, subtract that from 1st group, append second group, set as later Ranges

    # Match any source reference
    def self.source_ref_regex
      %r{(?=.*([0-9]+\s*[a-zA-Z]+|[0-9]+\/+|[a-zA-Z]+\/+|[0-9]+&+|[a-zA-Z]+&+|OED|[a-zA-Z]+\s*[0-9]+|[A-Z]{2,}|[a-z][A-Z]))^[0-9a-zA-Z/.\[\]\-&, ?]*$}
    end

    # Matches words of the format  'ale-taster (2)'
    # Group 1: word e.g. 'ale-taster'
    # Group 2: word index e.g. 2
    def self.headword_regex
      /([a-zA-Z\-\s]+)\s*(?:\((\d*)\))?/
    end

    # Matches the page numbers at the end of an archival reference.
    # Also works for roman nums.
    # arch.ref 'a/b/c/1,3' matches '1,3'
    # arch.ref '1-5' matches '1-5'
    # arch.ref '1' matches '1'
    def self.archival_pages_regex
      %r{(.*\/)?((?:[\dcxlijv]+n?[-, ]*)+)}
    end

    def self.place_name_regex
      /^[,a-zA-Z\s']+$/
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Import::ImportHelper.new.import
  data = {
    definition: Definition.first,
    sources: [
      { orig_reference: 'YAJ12/102', place: 'leeds; shef', date: 'c. 1335-45' },
      { orig_reference: 'YAJ12/102', place: 'leeds; shef', date: 'nd[1335-45]' }
    ]
  }

  # Import::ImportHelper.new.save_sources(Definition.first, data[:sources])

  # {orig_ref: 'YAJ12/102', place: 'leeds', date:'1335-65'}

  # test_sources.each do |s|
  #   Import::ImportHelper.clean_source s
  # end
end
