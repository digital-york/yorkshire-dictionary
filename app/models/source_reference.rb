# Class to represent a reference to a source material within a definition record.
# Each source triplet from the source CSV is a single reference, referring to a
# source material.
class SourceReference < ApplicationRecord
  belongs_to :definition
  belongs_to :source_material, optional: true

  has_many :places_source_references
  has_many :places, -> { distinct }, through: :places_source_references

  has_many :source_dates
  has_many :source_excerpts
end
