class CreateJoinTableSourceReferencesPlaces < ActiveRecord::Migration[5.2]
  def change
    create_join_table :source_references, :places do |t|
      t.index [:source_reference_id, :place_id], name: 'index_places_source_references_on_sr_id_and_p_id'
      t.index [:place_id, :source_reference_id], name: 'index_places_source_references_on_p_id_and_sr_id'
    end
  end
end
