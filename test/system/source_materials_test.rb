require "application_system_test_case"

class SourceMaterialsTest < ApplicationSystemTestCase
  setup do
    @source_material = source_materials(:one)
  end

  test "visiting the index" do
    visit source_materials_url
    assert_selector "h1", text: "Source Materials"
  end

  test "creating a Source material" do
    visit source_materials_url
    click_on "New Source Material"

    click_on "Create Source material"

    assert_text "Source material was successfully created"
    click_on "Back"
  end

  test "updating a Source material" do
    visit source_materials_url
    click_on "Edit", match: :first

    click_on "Update Source material"

    assert_text "Source material was successfully updated"
    click_on "Back"
  end

  test "destroying a Source material" do
    visit source_materials_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Source material was successfully destroyed"
  end
end
