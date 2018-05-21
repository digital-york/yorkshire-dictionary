# frozen_string_literal: true

class Word < ApplicationRecord
  has_many :definitions

  has_many :definition_sources, through: :definitions
  has_many :places, through: :definition_sources
  has_many :source_materials, through: :definition_sources
  
  def to_param
    text
  end

  def self.search(search)
    if search
      text = search[:text]
      places = search[:places]
      source_ref = search[:source_material_refs]
      source_ids = search[:source_material_ids]
      def_text = search[:def_text]
      letter = search[:letter]
      any = search[:any]

      query = joins(:definitions, :places, :source_materials)

      if any.present?
        query.where!(
          'definitions.text ILIKE :any OR definitions.discussion ILIKE :any OR words.text ILIKE :any OR places.name LIKE :any OR source_materials.original_ref ILIKE :any', any: "%#{any}%"
        )
      end

      if def_text.present?
        query.where!('definitions.text ILIKE \'%%%s%%\'', def_text)
              .or!(query.where('definitions.discussion ILIKE \'%%%s%%\'', def_text))
      end

      if letter.present?
        query.where!('words.text ILIKE \'%s%%\'', letter)
      end

      if text.present?
        query.where!('words.text ILIKE \'%%%s%%\'', text)
      end

      if places&.present?
        query.where!("places.id IN (?)", places)
      end

      if source_ref.present?
        query.where!('source_materials.original_ref ILIKE \'%%%s%%\'', source_ref)
      end
      
      if source_ids.present?
        query.where!('source_materials.id in (?)', source_ids)
      end

      results = query.distinct
    else
      results = all
    end
    results
  end
end
