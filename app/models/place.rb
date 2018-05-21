# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  has_many :definition_sources

  has_many :source_materials, through: :definition_sources
  has_many :definitions, through: :definition_sources

  has_many :words, through: :definitions
end
