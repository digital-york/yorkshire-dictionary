class CreateDefinitionRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :definition_relations do |t|
      t.integer "definition_id"
      t.integer "related_definition_id"
      t.string :relation_type

      t.timestamps
      
      t.index ["definition_id"], name: "index_definition_relations_on_definition_id"
      t.index ["related_definition_id"], name: "index_definition_relations_on_related_definition_id"
    end
  end
end
