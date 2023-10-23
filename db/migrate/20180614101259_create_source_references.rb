class CreateSourceReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :source_references do |t|
      t.references :definition, foreign_key: true
      t.references :source_material, foreign_key: true

      t.timestamps
    end
  end
end
