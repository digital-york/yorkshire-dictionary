# frozen_string_literal: true

# Model for representing a date associated with a definition source
class SourceDate < ApplicationRecord
  belongs_to :source_reference
end
