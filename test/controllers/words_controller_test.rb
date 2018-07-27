# frozen_string_literal: true

require 'test_helper'

class WordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @word = words(:one)
  end

  test 'should get index' do
    get words_url
    assert_response :success
  end

  test 'show word page should contain a network graph container for each def' do
    get word_url(@word)
    assert_select '#network-graph', count: @word.definitions.size
  end
end
