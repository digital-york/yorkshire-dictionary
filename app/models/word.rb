# frozen_string_literal: true

# Word class, which has many definitions
class Word < ApplicationRecord
  has_many :definitions

  has_many :definition_sources, through: :definitions
  has_many :places, through: :definition_sources
  has_many :source_materials, through: :definition_sources

  # Use the Word text as the param for the URL
  # https://apidock.com/rails/ActiveRecord/Base/to_param
  def to_param
    text
  end

  # Search for words
  def self.search(search)
    if search
      # Pull out individual params from the search parameter
      text = search[:text]
      places = search[:places]
      source_ids = search[:source_material_ids]
      def_text = search[:def_text]
      letter = search[:letter]
      any = search[:any]

      # Build a join on the tables of interest
      query = joins(:definitions, :places, :source_materials)
      
      # Clean up 2 array params, as they can equal [''], which should be classed as empty
      source_ids = check_empty_search_arrays source_ids
      places = check_empty_search_arrays places

      # Freeform query (searches any field of interest)
      if any.present?
        query.where!(
          'definitions.text ILIKE :any
          OR definitions.discussion ILIKE :any
          OR words.text ILIKE :any
          OR places.name LIKE :any
          OR source_materials.original_ref ILIKE :any',
          any: "%#{any}%"
        )
      end

      # Search definition text
      if def_text.present?
        query
          .where!('definitions.text ILIKE \'%%%s%%\'', def_text)
          .or!(
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

      # Only return each word once
      results = query.distinct
    else
      # If no search specified, return all words
      results = all
    end
    return results
  end

  def self.check_empty_search_arrays(array)
    if array&.size == 1 && array&.first == ''
      array = nil
    end
    return array
  end
end
