class RemoveCoOrdsFromPlaces < ActiveRecord::Migration[5.2]
  def change
    remove_column :places, :co_ords, :string
  end
end
