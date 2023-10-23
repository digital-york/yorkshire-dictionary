require 'test_helper'

class AltSpellingTest < ActiveSupport::TestCase
  test 'alt spellings should require text' do
    definition = definitions(:one)
    alt_s = definition.alt_spellings.create
    assert alt_s.errors[:text].any?

    alt_s.text = 'Test text'
    assert alt_s.valid?
  end
end
