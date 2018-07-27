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

  test 'should get new' do
    get new_source_material_url
    assert_response :success
  end

  test 'should create source_material' do
    assert_difference('SourceMaterial.count') do
      post source_materials_url, params: { source_material: {} }
    end

    assert_redirected_to source_material_url(SourceMaterial.last)
  end

  test 'should show source_material' do
    get source_material_url(@source_material)
    assert_response :success
  end

  test 'should get edit' do
    get edit_source_material_url(@source_material)
    assert_response :success
  end

  test 'should update source_material' do
    patch source_material_url(@source_material), params: { source_material: {} }
    assert_redirected_to source_material_url(@source_material)
  end

  test 'should destroy source_material' do
    assert_difference('SourceMaterial.count', -1) do
      delete source_material_url(@source_material)
    end

    assert_redirected_to source_materials_url
  end
end
