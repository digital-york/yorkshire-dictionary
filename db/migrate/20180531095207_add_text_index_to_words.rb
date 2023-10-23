class AddTextIndexToWords < ActiveRecord::Migration[5.2]
  def change
    add_index :words, :text
  end
end
