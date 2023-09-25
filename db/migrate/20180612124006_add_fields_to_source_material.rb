class AddFieldsToSourceMaterial < ActiveRecord::Migration[5.2]
  def change
    add_column :source_materials, :description, :text
    add_column :source_materials, :type, :integer
    add_column :source_materials, :archive, :string
    add_column :source_materials, :done, :boolean
    add_column :source_materials, :archive_checked, :boolean
  end
end
