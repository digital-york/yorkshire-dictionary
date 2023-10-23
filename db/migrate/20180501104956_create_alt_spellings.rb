class CreateAltSpellings < ActiveRecord::Migration[5.2]
  def change
    create_table :alt_spellings do |t|
      t.string :text

      t.timestamps
    end
  end
end
