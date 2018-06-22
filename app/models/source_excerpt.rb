# frozen_string_literal: true

# Class to represent a reference to a specific part of a source. For example, a 
# volume range, page range, or archival reference.
class SourceExcerpt < ApplicationRecord
  belongs_to :source_reference
end
