class CreateDefinitions < ActiveRecord::Migration[5.2]
  def change
    create_table :definitions do |t|
      t.text :text
      t.text :discussion

      t.timestamps
    end
  end
end
