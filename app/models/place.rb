# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  after_validation :geocode, if: ->(place) { place.name.present? && place.latitude.nil? }

  # Join table
  has_many :places_source_references

  # Mapped through join table
  has_many :source_references, through: :places_source_references

  has_many :definitions, -> { distinct }, through: :source_references
  has_many :source_materials, -> { distinct }, through: :source_references

  # Mapped through other mapping
  has_many :words, -> { distinct }, through: :definitions

  def geocode
    lat_long = YhdGeocodeService.geocode(name)
    self.latitude = lat_long[:latitude]
    self.longitude = lat_long[:longitude]
  end
end
