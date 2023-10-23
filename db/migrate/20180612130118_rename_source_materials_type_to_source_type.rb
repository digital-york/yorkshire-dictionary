class RenameSourceMaterialsTypeToSourceType < ActiveRecord::Migration[5.2]
  def change
    rename_column :source_materials, :type, :source_type
  end
end
