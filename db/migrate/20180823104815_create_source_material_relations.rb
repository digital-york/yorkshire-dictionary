class CreateSourceMaterialRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :source_material_relations do |t|
      t.integer "source_material_id"
      t.integer "parent_source_material_id"

      t.timestamps

      t.index ["source_material_id"], name: "index_source_material_relations_on_source_material_id"
      t.index ["parent_source_material_id"], name: "index_source_material_relations_on_parent_source_material_id"
    end
  end
end