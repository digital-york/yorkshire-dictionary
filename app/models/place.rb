# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  # See geocoder gem @ https://github.com/alexreisner/geocoder
  # Set bounds to yorkshire and region to GB
  geocoded_by :name, :params => {:region => "gb", :bounds => [[54.9616, 0.72532], [52.9186,-3.05396]]}
  after_validation :geocode, if: -> (obj) { obj.name.present? and obj.latitude.nil? }

  # Join table
  has_many :definition_sources

  # Mapped through join table
  has_many :source_materials, through: :definition_sources
  has_many :definitions, through: :definition_sources

  # Mapped through other mapping
  has_many :words, through: :definitions
end
