class AddForeignKeyConstraintToDefinitionRelationsDefinitionId < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :definition_relations, :definitions
  end
end
