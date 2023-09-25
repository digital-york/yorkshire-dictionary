require 'test_helper'
require "#{Rails.root}/lib/import/bibliography_loader"
require 'csv'

class BibliographyLoaderTest < ActiveSupport::TestCase

  @@bibliography_data = BibliographyLoader.new.load('bib_test.csv')

  test 'duplicate sources are saved to a single reference' do
    title_count = SourceMaterial.select(:title).distinct.pluck(:title).count
    total_count = SourceMaterial.count
    assert_equal title_count, total_count
  end

  test 'parent sources are mapped' do
    assert_equal(
      SourceMaterial.find_by(title: 'child').parent.title,
      'parent'
    )
  end

  test 'all provided source references are returned' do
    missing_refs = false
    path = File.join(File.dirname(__FILE__), 'bib_test.csv')
    returned_refs = @@bibliography_data[:source_materials].map {|k, v| k}

    csv = CSV.read(path, "r:bom|utf-8")
    end_index = csv.size - 1
    csv[1..end_index].each do |row|
      if returned_refs.exclude? row[0].downcase
        missing_refs = true
        break
      end
    end
    assert missing_refs == false
  end

  test 'titles are saved' do
    assert SourceMaterial.find_by(title: 'test title').present?
  end

  test 'descriptions are saved' do
    assert_equal(
      SourceMaterial.find_by(title: 'test title').description,
      'test description'
    )
  end
  
  test 'short titles are saved' do
    assert_equal(
      SourceMaterial.find_by(title: 'test title').short_title,
      'test short title'
    )
  end

  test 'refs are saved in lowercase' do
    assert_equal(
      SourceMaterial.find_by(title: 'test title').original_ref,
      'test ref'
    )
  end
  
  test 'mis-spelled parents don\'t cause an error' do
    assert_nil(
      SourceMaterial.find_by(title: 'test title').parent
    )
  end

  test 're-importing the same data causes no changes' do
    bibliography_data_old = @@bibliography_data
    bibliography_data_new = BibliographyLoader.new.load('bib_test.csv')

    assert(
      bibliography_data_old == bibliography_data_new
    )
  end
end
