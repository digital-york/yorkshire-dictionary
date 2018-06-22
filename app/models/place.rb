# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  # See geocoder gem @ https://github.com/alexreisner/geocoder
  # Set bounds to yorkshire and region to GB
  geocoded_by :name, params:  { region: 'gb',
                                bounds: [[54.9616, 0.72532], [52.9186, -3.05396]],
                                components: 'administrative_area:yorkshire'}
  after_validation :geocode, if: ->(place) { place.name.present? && place.latitude.nil? }

  # Join table
  has_many :places_source_references

  # Mapped through join table
  has_many :source_references, through: :places_source_references

  has_many :definitions, through: :source_references
  has_many :source_materials, through: :source_references

  # Mapped through other mapping
  has_many :words, through: :definitions
end
