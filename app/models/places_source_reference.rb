# frozen_string_literal: true

# Link object for joining places and source references (many-to-many relationship)
class PlacesSourceReference < ApplicationRecord
  belongs_to :place
  belongs_to :source_reference
end
