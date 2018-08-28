# frozen_string_literal: true

require 'test_helper'

class SourceMaterialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # TODO: could use fixtures
    @source_material = SourceMaterial.create original_ref: 'test', ref: 'test'
  end

  test 'should get index' do
    get source_materials_url
    assert_response :success
  end

  test 'should show source_material' do
    get source_material_url(@source_material)
    assert_response :success
  end
end
