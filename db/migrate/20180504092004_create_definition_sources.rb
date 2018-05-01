class CreateDefinitionSources < ActiveRecord::Migration[5.2]
  def change
    create_table :definition_sources do |t|
      t.references :definition
      t.references :source_material
      t.references :place
      t.string :date

      t.timestamps
    end
  end
end
