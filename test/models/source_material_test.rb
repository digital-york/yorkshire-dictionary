require 'test_helper'

class SourceMaterialTest < ActiveSupport::TestCase
  test 'source materials can be created and linked to other records' do
    sm = SourceMaterial.create original_ref: 'test', ref: 'test'
    place = Place.create name: 'Test place'

    word = words(:one)
    definitions = word.definitions

    ref = definitions[0].source_references.create source_material: sm
    ref.places << place

    assert sm.places.size == 1
    assert sm.places.first == place
    assert sm.definitions.size == 1
    assert sm.definitions.first == definitions[0]

    assert sm.words.size == 1
    assert sm.words.first == word
  end
end
