class AddForeignKeyConstraintToDefinitionRelationsRelatedDefinitionId < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :definition_relations, :definitions, column: :related_definition_id, primary_key: :id
  end
end
