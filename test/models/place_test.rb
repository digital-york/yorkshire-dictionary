# frozen_string_literal: true

require 'test_helper'

class PlaceTest < ActiveSupport::TestCase
  test 'places should be geocodable' do
    place = Place.new name: 'York, UK'
    place.geocode
    assert place.latitude.present?
    assert place.longitude.present?
  end

  test 'places can be associated with other records' do
    place = Place.create name: 'Test place'
    sm = SourceMaterial.create original_ref: 'test', ref: 'test'

    word = words(:one)
    definitions = word.definitions

    def_source_ref = definitions[0].source_references.create source_material: sm
    def_source_ref.places << place

    assert place.source_references.size == 1
    assert place.source_materials.size == 1
    assert place.definitions.size == 1
    assert place.words.size == 1

    assert place.source_references.first == def_source_ref
    assert place.source_materials.first == sm
    assert place.definitions.first == definitions[0]
    assert place.words.first == word
  end
end
