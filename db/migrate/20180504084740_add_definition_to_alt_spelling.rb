class AddDefinitionToAltSpelling < ActiveRecord::Migration[5.2]
  def change
    add_reference :alt_spellings, :definition, foreign_key: true
  end
end
