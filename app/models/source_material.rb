# frozen_string_literal: true

# Class for a source material
class SourceMaterial < ApplicationRecord
  has_many :definition_sources
  has_many :definitions, through: :definition_sources
end
