class CreateSourceExcerpts < ActiveRecord::Migration[5.2]
  def change
    create_table :source_excerpts do |t|
      t.references :source_reference, foreign_key: true
      t.integer :volume_start
      t.integer :volume_end
      t.integer :page_start
      t.integer :page_end
      t.string :archival_ref

      t.timestamps
    end
  end
end
