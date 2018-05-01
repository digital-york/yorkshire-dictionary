# frozen_string_literal: true

# Relationship between two related definitions
class DefinitionRelation < ApplicationRecord
  belongs_to :definition
  belongs_to :related_definition, class_name: 'Definition'
end
