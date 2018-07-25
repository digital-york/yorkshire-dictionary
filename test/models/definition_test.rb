require 'test_helper'

class DefinitionTest < ActiveSupport::TestCase

  test 'definitions should require text' do
    defi = words(:one).definitions.create
    assert defi.save == false

    defi.text = 'Test text'
    assert defi.save
  end

  test 'word definitions can have alternate spellings' do
    word = words(:one)
    definitions = word.definitions
    definition = definitions[0]

    alt = definition.alt_spellings.create text: 'Test alt spelling'
    assert AltSpelling.all.size == 1
    assert alt.definition == definition
    assert alt.definition.word == word
  end

  test 'word definitions can have sources' do
    word = words(:one)
    definitions = word.definitions

    definition = definitions[0]

    sm = SourceMaterial.create original_ref: 'test', ref: 'test'

    definition.source_materials << sm

    assert SourceMaterial.all.size == 1
    assert sm.definitions.include? definition
    assert definition.source_materials.include? sm
  end
end
