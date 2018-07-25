# frozen_string_literal: true

require 'test_helper'

class WordTest < ActiveSupport::TestCase
  test 'creating a word works' do
    word = get_word
    assert Word.all.size == 1
  end

  test 'definitions can be browsed from a word' do
    word = get_word

    definitions = get_definitions word

    assert Definition.all.size == 2
    assert definitions[0].word == word
    assert definitions[1].word == word
    assert word.definitions[0] == definitions[0]
    assert word.definitions[1] == definitions[1]
  end

  test 'word definitions can have alternate spellings' do
    word = get_word
    definitions = get_definitions word
    definition = definitions[0]

    alt = definition.alt_spellings.create text: 'Test alt spelling'
    assert AltSpelling.all.size == 1
    assert alt.definition == definition
    assert alt.definition.word == word
  end

  test 'word definitions can have sources' do
    word = get_word
    definitions = get_definitions word

    definition = definitions[0]

    sm = SourceMaterial.create original_ref: 'test', ref: 'test'

    definition.source_materials << sm

    assert SourceMaterial.all.size == 1
    assert sm.definitions.include? definition
    assert definition.source_materials.include? sm
  end

  test 'places can be associated with other records' do
    place = Place.create name: 'Test place'
    sm = SourceMaterial.create original_ref: 'test', ref: 'test'

    word = get_word
    definitions = get_definitions word

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

  test 'source materials can be created and linked to other records' do
    sm = SourceMaterial.create original_ref: 'test', ref: 'test'
    place = Place.create name: 'Test place'

    word = get_word
    definitions = get_definitions word

    ref = definitions[0].source_references.create source_material: sm
    ref.places << place

    assert sm.places.size == 1
    assert sm.places.first == place
    assert sm.definitions.size == 1
    assert sm.definitions.first == definitions[0]

    assert sm.words.size == 1
    assert sm.words.first == word
  end

  private

  def get_word
    Word.create text: 'Test word'
  end

  def get_definitions(word)
    def1 = word.definitions.create text: 'Example def 1'
    def2 = word.definitions.create text: 'Example def 2'

    [def1, def2]
  end
end
