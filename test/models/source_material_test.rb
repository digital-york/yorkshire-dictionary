require 'test_helper'

class SourceMaterialTest < ActiveSupport::TestCase
  test 'source materials can be created and linked to other records' do
    sm = SourceMaterial.create original_ref: 'test', ref: 'test'
    place = Place.create name: 'Test place'

    word = words(:one)
    definitions = word.definitions

    ref = definitions.first.source_references.create source_material: sm
    ref.places << place

    assert sm.places.size.positive?
    assert sm.places.first == place
    assert sm.definitions.size.positive?
    assert sm.definitions.first == definitions.first

    assert sm.words.size.positive?
    assert sm.words.first == word
  end
end
