# frozen_string_literal: true

require_relative 'csv_loader'
require_relative '../../config/environment'

# frozen_string_literal: true
class BibliographyLoader
  def load
    # Instantiate hash of source objects, keyed by original (GRD) reference
    source_objs = {}

    archival_refs = {}

    # Load CSV rows from bibliography
    bibliography = CsvLoader.load_csv 'bibliography.csv'

    # Instantiate list of header names from bib
    bib_headers = []

    # Inst. hash of field name, to its index in the header row
    bib_field_indexes = {}

    # Loop through header, recording index of each field in bib_field_indexes
    bibliography[0].each_with_index do |bib_header, i|
      sym = nil
      bib_headers[i] = bib_header
      case bib_header
      when 'GRD Ref'
        sym = :orig_ref
      when 'Source Title'
        sym = :title
      when 'Excerpt Description'
        sym = :description
      when 'Done?'
        sym = :done
      when 'Archival Ref'
        sym = :archival_ref
      when 'Archive'
        sym = :archive
      when 'Checked with archive'
        sym = :archive_checked
      when 'Type'
        sym = :source_type
      end

      bib_field_indexes[sym] = i if sym
    end

    # For each source in bib, create source material obj
    bibliography[1..-1].each do |source|
      orig_ref = source[bib_field_indexes[:orig_ref]]&.downcase
      title = source[bib_field_indexes[:title]]

      unless orig_ref
        puts "Skipped bibliography entry for having no reference."
        next
      end

      unless title
        puts "Skipped bibliography entry for having no title (#{orig_ref})"
        next
      end

      description = source[bib_field_indexes[:description]]
      done = source[bib_field_indexes[:done]]
      archival_ref = source[bib_field_indexes[:archival_ref]]
      archive = source[bib_field_indexes[:archive]]
      archive_checked = source[bib_field_indexes[:archive_checked]]
      source_type = source[bib_field_indexes[:source_type]]&.downcase

      # Create source obj, set values if new only
      sm = SourceMaterial.where(title: title).first_or_create do |new_record|
        new_record.update(
          original_ref: orig_ref,
          title: title,
          description: description,
          done: done,
          ref: archival_ref,
          archive: archive,
          archive_checked: archive_checked,
          source_type: source_type # TODO: what about if no source type?
        )
      end

      # Report errors
      puts sm.errors.full_messages

      # Add new obj to map of sources
      source_objs[orig_ref] = [] unless source_objs[orig_ref]
      source_objs[orig_ref] << sm

      archival_refs[orig_ref] = archival_ref if archival_ref&.present?
    end

    reference_regex = reference_regex(source_objs.keys)
    {
      source_materials: source_objs,
      archival_refs: archival_refs,
      reference_regex: reference_regex
    }
  end

  def reference_regex(sources)
    sorted =  sources
              .map { |x| Regexp.escape x }
              .map(&:strip)
              .sort_by(&:length)
              .reverse

    joined = sorted.join '|'
    regex = Regexp.new "^(#{joined})(.*)", 'i'
    regex
  end
end

if $PROGRAM_NAME == __FILE__
  bibliography_data = BibliographyLoader.new.load

  bibliography_data[:reference_regex]
end
