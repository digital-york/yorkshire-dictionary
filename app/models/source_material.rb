# frozen_string_literal: true

# Class for a source material - for example, a book, a volume, or a piece of
# content within an archive.
class SourceMaterial < ApplicationRecord
  enum source_type: [:book, :archival]

  has_many :source_references

  has_many :definitions, -> { distinct }, through: :source_references
  has_many :source_dates, through: :source_references
  has_many :source_reference_places, through: :source_references
  
  has_many :places, -> { distinct }, through: :source_reference_places

  has_many :words, -> { distinct }, through: :definitions
end
