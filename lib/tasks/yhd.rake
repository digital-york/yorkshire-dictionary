# frozen_string_literal: true

require "#{Rails.root}/lib/import/import"

namespace :yhd do
  desc 'TODO'
  task import: :environment do
    Import::ImportHelper.new.import
  end
end
