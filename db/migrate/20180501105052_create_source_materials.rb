class CreateSourceMaterials < ActiveRecord::Migration[5.2]
  def change
    create_table :source_materials do |t|
      t.string :name
      t.string :ref
      t.string :original_ref

      t.timestamps
    end
  end
end
