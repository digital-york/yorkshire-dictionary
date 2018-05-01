class AddWordToDefinition < ActiveRecord::Migration[5.2]
  def change
    add_reference :definitions, :word, foreign_key: true
  end
end
