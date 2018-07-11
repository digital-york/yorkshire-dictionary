# frozen_string_literal: true

# Class for places, which are used by Sources
class Place < ApplicationRecord
  # See geocoder gem @ https://github.com/alexreisner/geocoder
  # Set bounds to yorkshire and region to GB
  geocoded_by :name, params:  { countrycode: 'gb'} do |obj, results|
    closest_distance = nil
    closest_result = nil

    york = { latitude: 53.95763, longitude:-1.08271 }

    results.each do |result|
      lat_difference = (york[:latitude] - result.latitude).abs
      long_difference = (york[:longitude] - result.longitude).abs

      euclidean_distance = Math.sqrt(lat_difference**2 + long_diff**2)
      if (closest_result.nil? || euclidean_distance < closest_distance)
        closest_distance = euclidean_distance
        closest_result = result
      end
    end

    if closest_result
      obj.latitude = closest_result.latitude
      obj.longitude = closest_result.longitude
    end
  end
  
  after_validation :geocode, if: ->(place) { place.name.present? && place.latitude.nil? }

  # Join table
  has_many :places_source_references

  # Mapped through join table
  has_many :source_references, through: :places_source_references

  has_many :definitions, -> { distinct }, through: :source_references
  has_many :source_materials, -> { distinct }, through: :source_references

  # Mapped through other mapping
  has_many :words, -> { distinct }, through: :definitions
end
