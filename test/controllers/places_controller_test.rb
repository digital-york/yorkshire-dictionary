# frozen_string_literal: true

require 'test_helper'

class PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @place = places(:one)
  end

  test 'should get index' do
    get places_url
    assert_response :success
  end

  test 'place view should contain map container' do
    get place_url(@place)
    assert_select '#map'
  end

  test 'index should contain map container' do
    get places_url
    assert_select '#map'
  end

  test 'should show place' do
    get place_url(@place)
    assert_response :success
  end

end
