class DropDefinitionSourcesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :definition_sources
  end
end
