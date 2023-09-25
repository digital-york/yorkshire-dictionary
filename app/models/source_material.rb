# frozen_string_literal: true

# Class for a source material - for example, a book, a volume, or a piece of
# content within an archive.
class SourceMaterial < ApplicationRecord
  enum source_type: %i[book archival]

  has_many :source_references

  belongs_to :parent, class_name: 'SourceMaterial', foreign_key: 'parent_id',
                      optional: true

  has_many :children, class_name: 'SourceMaterial', foreign_key: 'parent_id'

  # TODO: dependents
  has_many :definitions, -> { distinct }, through: :source_references
  has_many :source_excerpts, through: :source_references
  has_many :source_dates, through: :source_references
  has_many :places_source_references, through: :source_references

  has_many :places, -> { distinct }, through: :places_source_references

  has_many :words, -> { distinct }, through: :definitions

  def short_display_title
    if short_title.present?
      short_title
    else
      display_title
    end
  end

  def display_title
    if title.present?
      title
    else
      'Untitled Source'
    end
  end
end
