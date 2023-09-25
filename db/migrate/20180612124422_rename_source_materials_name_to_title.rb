class RenameSourceMaterialsNameToTitle < ActiveRecord::Migration[5.2]
  def change
    rename_column :source_materials, :name, :title
  end
end
