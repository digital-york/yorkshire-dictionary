# frozen_string_literal: true

require 'test_helper'

class WordTest < ActiveSupport::TestCase
  test 'definitions can be browsed from a word' do
    word = words(:one)

    definitions = word.definitions

    assert Definition.all.size == 2
    assert definitions[0].word == word
    assert definitions[1].word == word
    assert word.definitions[0] == definitions[0]
    assert word.definitions[1] == definitions[1]
  end

  test 'word should require text' do
    word = Word.create
    assert word.save == false

    word.text = 'Test text'
    assert word.save
  end

  # test 'sources can be browsed from a word' do
  #   word = words(:one)

  # end
end
