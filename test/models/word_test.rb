# frozen_string_literal: true

require 'test_helper'

class WordTest < ActiveSupport::TestCase
  test 'definitions can be browsed from a word' do
    word = words(:one)

    definitions = word.definitions

    assert Definition.all.size >= 2
    assert definitions.first.word == word
    assert definitions.second.word == word
    assert word.definitions.first == definitions.first
    assert word.definitions.second == definitions.second
  end

  test 'word should require text' do
    word = Word.create
    assert word.errors[:text].any?

    word.text = 'Test text'
    assert word.valid?
  end
end
