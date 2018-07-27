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

  test 'should get new' do
    get new_place_url
    assert_response :success
  end

  test 'should create place' do
    assert_difference('Place.count') do
      post places_url, params: { place: {} }
    end

    assert_redirected_to place_url(Place.last)
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

  test 'should get edit' do
    get edit_place_url(@place)
    assert_response :success
  end

  test 'should update place' do
    patch place_url(@place), params: { place: {} }
    assert_redirected_to place_url(@place)
  end

  test 'should destroy place' do
    assert_difference('Place.count', -1) do
      delete place_url(@place)
    end

    assert_redirected_to places_url
  end
end
