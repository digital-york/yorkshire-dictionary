require 'test_helper'

class DefinitionTest < ActiveSupport::TestCase

  test 'word definitions can have alternate spellings' do
    word = words(:one)
    definition = word.definitions.first

    alt = definition.alt_spellings.create text: 'Test alt spelling'
    assert AltSpelling.all.size.positive?
    assert alt.definition == definition
    assert alt.definition.word == word
    assert word.alt_spellings.include? alt
  end

  test 'word definitions can have sources' do
    word = words(:one)
    definition = word.definitions.first

    sm = SourceMaterial.create original_ref: 'test', ref: 'test'

    definition.source_materials << sm

    assert SourceMaterial.all.size.positive?
    assert sm.definitions.include? definition
    assert definition.source_materials.include? sm
  end
end
