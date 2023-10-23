require 'test_helper'

class DefinitionRelationTest < ActiveSupport::TestCase
  def setup
    @defi = definitions(:one)
    @related = definitions(:two)
    @defi.related_definitions << @related
  end

  test 'definition relations can be accessed' do
    assert @defi.related_definitions.include? @related
  end

  test 'inverse definition relations can be accessed' do
    assert @related.inverse_related_definitions.include? @defi
  end

  test 'definition relations shouldn\'t include inverse relations' do
    assert @related.related_definitions.exclude? @defi
  end

  test 'inverse definition relations shouldn\'t include regular relations' do
    assert @defi.inverse_related_definitions.exclude? @related
  end
end
