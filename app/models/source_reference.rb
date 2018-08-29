# Class to represent a reference to a source material within a definition record.
# Each source triplet from the source CSV is a single reference, referring to a
# source material.
class SourceReference < ApplicationRecord
  belongs_to :definition
  belongs_to :source_material, optional: true

  has_one :word, through: :definition

  has_many :places_source_references, dependent: :delete_all
  has_many :places, -> { distinct }, through: :places_source_references

  has_many :source_dates, dependent: :delete_all
  has_many :source_excerpts, dependent: :delete_all

  def reference_string
    s = StringIO.new
    s << source_material.display_title
    s << " (#{excerpts_string})" if excerpts_string.present?
    s.string
  end

  def excerpts_string
    source_excerpts.map(&:excerpt_string).join(', ')
  end
end
