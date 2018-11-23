source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'jquery-rails', '~> 4.3.3'
gem 'jquery-ui-rails', '~> 6.0.1'

gem "js-routes", '~> 1.4.4'

gem 'vis-gem', '~> 4.21.0.0'

# For pagination
gem 'will_paginate', '~> 3.1.0'

# Geocoding
gem 'geocoder', '~> 1.4.8'

# Mapping
gem 'leaflet-rails', '~> 1.3.1'

gem "passenger", ">= 5.0.25", require: "phusion_passenger/rack_handler"
gem "rack", ">= 2.0.6"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

gem 'bootstrap', '~> 4.1.1'

gem 'sprockets-rails', '~> 3.2.1'

gem 'pg', '~> 1.0.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 10.0.2', platforms: [:mri, :mingw, :x64_mingw]
  gem 'ruby-debug-ide', '~> 0.7.0.beta6'
  gem 'debase', '~> 0.2.3.beta2'
  gem 'xray-rails', '~> 0.3.1'
  gem 'jasmine-rails', '~> 0.14.8'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 2.0.2'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Performance monitoring
  gem 'bullet', '~> 5.7.5'

  gem 'puma'
end

group :heroku do
  gem 'sendgrid-ruby'
end


group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver', '~> 3.11.0'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper', '~> 1.2.0'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2.5', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "loofah", ">= 2.2.3"
