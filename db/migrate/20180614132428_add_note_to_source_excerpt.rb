class AddNoteToSourceExcerpt < ActiveRecord::Migration[5.2]
  def change
    add_column :source_excerpts, :note, :boolean
  end
end
