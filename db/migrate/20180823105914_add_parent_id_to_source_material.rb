class AddParentIdToSourceMaterial < ActiveRecord::Migration[5.2]
  def change
    add_column :source_materials, :parent_id, :integer
  end
end
