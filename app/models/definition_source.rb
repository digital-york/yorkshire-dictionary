class DefinitionSource < ApplicationRecord
  belongs_to :place, optional: true
  belongs_to :source_material
  belongs_to :definition
end
