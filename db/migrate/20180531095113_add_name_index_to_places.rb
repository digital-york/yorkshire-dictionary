class AddNameIndexToPlaces < ActiveRecord::Migration[5.2]
  def change
    add_index :places, :name
  end
end
