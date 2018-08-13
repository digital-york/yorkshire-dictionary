# frozen_string_literal: true

# Word class, which has many definitions
class Word < ApplicationRecord
  validates :text, presence: true

  has_many :definitions

  has_many :source_references, through: :definitions
  has_many :alt_spellings, through: :definitions
  has_many :source_dates, through: :definitions
  has_many :places, -> { distinct }, through: :definitions
  has_many :source_materials, -> { distinct }, through: :definitions

  # Use the Word text as the param for the URL
  # https://apidock.com/rails/ActiveRecord/Base/to_param
  def to_param
    text
  end

  # Search for words
  def self.search(search)
    if search
      # Remove anything that isn't a letter or hyphen from fields which contain
      # free text.
      cleanable_fields = [search[:def_text], search[:text]]
      cleanable_fields.each do |_k, v|
        next if v.nil?
        v.gsub!(/[^a-zA-Z\-\s]+/, '')
      end

      # Pull out individual params from the search parameter
      text = search[:text]
      places = search[:places]
      source_ids = search[:source_material_ids]
      def_text = search[:def_text]
      start_year = search[:start_year]
      end_year = search[:end_year]
      letter = search[:letter]
      any = search[:any]

      # Build a join on the tables of interest
      query = joins(:definitions, :places, :source_materials, :source_dates)
              .includes(
                definitions: [
                  { related_definitions: :word },
                  :places,
                  :alt_spellings
                ]
              )

      # Clean up 2 array params, as they can equal [''], which should be classed as empty
      source_ids = check_empty_search_arrays source_ids
      places = check_empty_search_arrays places

      # Freeform query (searches any field of interest)
      if any.present?
        query.where!(
          'definitions.text ILIKE :any
          OR definitions.discussion ILIKE :any
          OR words.text ILIKE :any
          OR places.name LIKE :any
          OR source_materials.title ILIKE :any',
          any: "%#{any}%"
        )
      end

      # Search definition text
      if def_text.present?
        query = query
                .where('definitions.text ILIKE \'%%%s%%\'', def_text)
                .or(
                  query.where('definitions.discussion ILIKE \'%%%s%%\'', def_text)
                )
      end

      # Search by first letter
      query.where!('words.text ILIKE \'%s%%\'', letter) if letter.present?

      # Search by  word text
      query.where!('words.text ILIKE \'%%%s%%\'', text) if text.present?

      # Search by place ID
      query.where!('places.id IN (?)', places) if places&.present?

      # Search by source IDs
      query.where!('source_materials.id in (?)', source_ids) if source_ids&.present?

      # If there is a start date set, end date must be before it
      query.where!('source_dates.end_year > ?', start_year) if start_year&.present?

      # If there is an end date set, start date must be after it
      query.where!('source_dates.start_year < ?', end_year) if end_year&.present?

      # Only return each word once
      results = query.distinct
    else
      # If no search specified, return all words
      results = all
    end
    results
  end

  def self.check_empty_search_arrays(array)
    array = nil if array&.size == 1 && array&.first == ''
    array
  end
end
