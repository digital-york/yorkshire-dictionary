class CreateSourceDates < ActiveRecord::Migration[5.2]
  def change
    create_table :source_dates do |t|
      t.integer :start_year
      t.integer :end_year
      t.boolean :circa
      t.boolean :estimate
      t.references :source_reference, foreign_key: true

      t.timestamps
    end
  end
end
