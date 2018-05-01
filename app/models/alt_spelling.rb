# frozen_string_literal: true

# Class for alternate spellings, which some dictionary definitions have
class AltSpelling < ApplicationRecord
  belongs_to :definition
end
