# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  # See geocoder gem @ https://github.com/alexreisner/geocoder
  geocoded_by :name
  after_validation :geocode, if: -> (obj) { obj.name.present? and obj.latitude.nil? }

  # Join table
  has_many :definition_sources

  # Mapped through join table
  has_many :source_materials, through: :definition_sources
  has_many :definitions, through: :definition_sources

  # Mapped through other mapping
  has_many :words, through: :definitions
end
