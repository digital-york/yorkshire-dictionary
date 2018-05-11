# frozen_string_literal: true

class Word < ApplicationRecord
  has_many :definitions

  has_many :definition_sources, through: :definitions
  has_many :places, through: :definition_sources
  has_many :source_materials, through: :definition_sources

  def self.search(search)
    if search
      text = search[:text]
      place = search[:place]
      source_ref = search[:source_materials]
      def_text = search[:def_text]

      query = joins(:definitions, :places, :source_materials)

      unless def_text&.empty?
        query.where!('definitions.text LIKE "%%%s%%"', def_text)
              .or!(query.where('definitions.discussion LIKE "%%%s%%"', def_text))
      end

      query.where!('words.text LIKE "%%%s%%"', text) unless text&.empty?

      query.where!('places.name LIKE "%%%s%%"', place) unless place&.empty?

      unless source_ref&.empty?
        query.where!('source_materials.original_ref LIKE "%%%s%%"', source_ref)
      end

      results = query.distinct

    else
      results = all
    end
    results
  end
end
