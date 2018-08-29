# frozen_string_literal: true

require_relative 'date_extractor'
require_relative 'error_reporter'

module Import
  class SourceSaver

    def initialize(error_reporter = ErrorReporter.new)
      @error_reporter = error_reporter

      # Map of place_name -> Place
      @places = {}
    end

    def save_sources(definition, sources, bibliography_data)
      # Remove existing source references for the current def.
      SourceReference.where(definition: definition).destroy_all

      source_material_refs = Hash.new { |h, k| h[k] = [] }

      # Save each source otherwise
      sources.each_with_index do |source, index|
        definition = definition

        if source.nil?
          @error_reporter.report_error definition.word.text,
                        "Source #{index + 1}: Source is missing - should move subsequent sources to fill missing source.",
                        'error'
          next
        end

        source_ref_string = source[:orig_reference]

        # No ref found in the source data
        unless source_ref_string && self.class.source_ref_regex.match?(source_ref_string)
          @error_reporter.report_error definition.word.text,
                        "Source #{source[:source_number]}: Source reference '#{source_ref_string}' doesn't match expected format. Skipping.",
                        'error'
          next
        end

        # Run regex to match components of the source reference string
        source_reference_match = bibliography_data[:reference_regex].match source_ref_string

        unless source_reference_match
          @error_reporter.report_error definition.word.text,
                        "Source #{source[:source_number]}: No source record in bibliography matched for #{source_ref_string}",
                        'error'
          next
        end

        # Extract the reference from the regex match
        source_material_reference = source_reference_match[1]

        unless source_material_reference
          # TODO: error, no source reference found in source string
        end

        # Retrieve the corresponding source material
        source_materials = bibliography_data[:source_materials][source_material_reference.downcase] || []

        # FIXME: this next error check was moved, might not make sense here
        unless source_materials.any?
          @error_reporter.report_error definition.word.text,
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
          source_reference_match = bibliography_data[:reference_regex].match source_ref_string

          # Extract the reference to the excerpt
          # (volume and/or page number, or arch. ref)
          preset_archival_ref = bibliography_data[:archival_refs][source_ref_string.downcase]
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

    def save_dates(source_number, date_string, source_reference)
      return if DateExtractor.nd_regex.match? date_string

      # Check for date, attempt to get date from field if match
      # TODO: handle date_string being nil, empty
      # TODO: need to track which dates match the above regexes but not the general one, and update to match
      dates = DateExtractor.get_dates date_string
      # TODO: need to report errors if dates.failures is not empty, one for each

      if dates.empty?
        @error_reporter.report_error source_reference.definition.word.text,
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
        @error_reporter.report_error  source_reference.definition.word.text,
                      "Source #{source_number}: No place name included for source. Use 'np' to specify no associated place.",
                      'warn'
        return
      end

      places_strings = places_string.split ';'
      places_strings.each do |place_name|
        unless self.class.place_name_regex.match? place_name
          @error_reporter.report_error source_reference.definition.word.text,
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
          @error_reporter.report_error definition.word.text,
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
          @error_reporter.report_error definition, 'Multiple volumes and pages specified for a single reference', 'error'
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
          @error_reporter.report_error(
            definition.word.text,
            "Invalid archival excerpt reference - '#{excerpt_reference}'. Using anyway, but check. Expected format is source_reference/excerpt_reference (with slash) e.g. BIA/3/4/2.",
            'warn'
          )
          sub_reference = excerpt_reference
        end

        # FIXME: next line commented?
        # page_regex_match = ImportHelper.archival_pages_regex.match sub_reference
        SourceExcerpt
          .where(
            source_reference: source_reference,
            archival_ref: sub_reference
          )
          .first_or_create
      else
        @error_reporter.report_error definition, "Unknown source type: #{source_material.source_type}", 'error'
      end
      end

    # Match any source reference
    def self.source_ref_regex
      %r{(?=.*([0-9]+\s*[a-zA-Z]+|[0-9]+\/+|[a-zA-Z]+\/+|[0-9]+&+|[a-zA-Z]+&+|OED|[a-zA-Z]+\s*[0-9]+|[A-Z]{2,}|[a-z][A-Z]))^[0-9a-zA-Z/.\[\]\-&, ?]*$}
    end

    def self.place_name_regex
      /^[,a-zA-Z\s']+$/
    end

    # Matches the page numbers at the end of an archival reference.
    # Also works for roman nums.
    # arch.ref 'a/b/c/1,3' matches '1,3'
    # arch.ref '1-5' matches '1-5'
    # arch.ref '1' matches '1'
    # TODO: only used in commented out line - delete?
    def self.archival_pages_regex
      %r{(.*\/)?((?:[\dcxlijv]+n?[-, ]*)+)}
    end
  end
end

# # Matches the source reference, and retrieves the relevant source materials
# # for that reference. The sub-reference is parsed, and a SourceReference &
# # SourceExcerpt objects created.
# def handle_source_ref_related_saves(source_number, source_ref_string, definition)
#   definition = definition

#   # No ref found in the source data
#   unless source_ref_string && self.class.source_ref_regex.match?(source_ref_string)
#     @error_reporter.report_error  definition,
#                   "Source #{source_number}: Source reference '#{source_ref_string}' doesn't match expected format. Skipping.",
#                   'error'
#     return []
#   end

#   # Run regex to match components of the source reference string
#   source_reference_match = @bibliography_data[:reference_regex].match source_ref_string

#   unless source_reference_match
#     @error_reporter.report_error  definition,
#                   "Source #{source_number}: No source record in bibliography matched for #{source_ref_string}",
#                   'error'
#     return []
#   end

#   # Extract the reference from the regex match
#   source_material_reference = source_reference_match[1]

#   unless source_material_reference
#     # TODO: error, no source reference found in source string
#   end

#   # Retrieve the corresponding source material
#   source_materials = @bibliography_data[:source_materials][source_material_reference.downcase] || []

#   unless source_materials.any?
#     @error_reporter.report_error  definition,
#                   "Source #{source_number}: No source material loaded from bibliography for #{source_material_reference}",
#                   'error'
#   end

#   # Extract the reference to the excerpt
#   # (volume and/or page number, or arch. ref)
#   preset_archival_ref = @bibliography_data[:archival_refs][source_ref_string.downcase]
#   excerpt_reference = if preset_archival_ref&.present?
#                         preset_archival_ref
#                       else
#                         source_reference_match[2]
#                       end

#   source_references = []
#   source_materials.each do |source_material|
#     # save_source(definition, source, index+1) unless source.nil?
#     source_reference_obj = SourceReference.create definition: definition, source_material: source_material
#     save_source_excerpts(source_number, source_material, excerpt_reference, source_reference_obj)
#     source_references << source_reference_obj
#   end
#   source_references
# end
