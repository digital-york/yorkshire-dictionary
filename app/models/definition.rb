# frozen_string_literal: true

# Definition of a word in a dictionary
class Definition < ApplicationRecord
  belongs_to :word

  has_many :alt_spellings

  has_many :source_references
  has_many :source_dates, through: :source_references

  has_many :source_materials, -> { distinct }, through: :source_references
  has_many :places, -> { distinct }, through: :source_references

  # Associations for related definitions
  has_many :definition_relations

  has_many :inverse_definition_relations,
           class_name: 'DefinitionRelation',
           foreign_key: 'related_definition_id'

  has_many :related_definitions,
           through: :definition_relations, class_name: 'Definition'

  has_many :inverse_related_definitions,
           through: :inverse_definition_relations, source: :definition,
           class_name: 'Definition'
end
