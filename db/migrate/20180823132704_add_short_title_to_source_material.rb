class AddShortTitleToSourceMaterial < ActiveRecord::Migration[5.2]
  def change
    add_column :source_materials, :short_title, :string
  end
end
