# frozen_string_literal: true

require 'test_helper'
require "#{Rails.root}/lib/import/bibliography_loader"
require "#{Rails.root}/lib/import/import"
require 'csv'

class ImportTest < ActiveSupport::TestCase
  @bibliography_data = BibliographyLoader.new.load('bib_test.csv')

  class << self
    attr_reader :bibliography_data
  end

  test 'all sources are linked correctly' do
    Import::ImportHelper.new(self.class.bibliography_data).import('yhd_test.csv')
    titles = Word.find_by(text: 'kirk maister').source_materials.map(&:title)

    assert titles.include? 'Will of Brian Otes, Halifax, 4 August 1529'
  end
end
