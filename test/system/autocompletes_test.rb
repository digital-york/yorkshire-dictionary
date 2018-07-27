# frozen_string_literal: true

require 'application_system_test_case'

class AutocompletesTest < ApplicationSystemTestCase
  test 'places autocomplete should work on places index' do
    visit places_url

    auto_complete_field = 'place_autocomplete'
    fill_in auto_complete_field, with: 'Yo'
    page.execute_script %{ $('##{auto_complete_field}').trigger("keydown") }
    assert_selector 'li.ui-menu-item div', text: 'York'
  end
end
