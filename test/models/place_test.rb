# frozen_string_literal: true

require 'test_helper'

class PlaceTest < ActiveSupport::TestCase
  test 'places should be geocodable' do
    place = Place.new name: 'York, UK'
    place.geocode
    assert place.latitude.present?
    assert place.longitude.present?
  end
end
