source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1', '>= 7.1.3.4'

# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'

# Use Uglifier as compressor for JavaScript assets
#gem 'uglifier', '>= 1.3.0'
gem 'terser'

# Use CoffeeScript for .coffee assets and views
#gem 'coffee-rails', '~> 5.0'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

gem 'jquery-rails', '~> 4.6'
gem 'jquery-ui-rails', '~> 7.0.0'

gem 'js-routes', '~> 2.0.0'

gem 'vis-gem', '~> 4.21.0.0'

# For pagination
gem 'will_paginate', '~> 3.3'

# Geocoding
gem 'geocoder', '~> 1.8'

# Mapping
gem 'leaflet-rails', '~> 1.9.5'

gem 'passenger', '>= 6.0.23', require: 'phusion_passenger/rack_handler'
gem 'rack', '~> 3.1', '>= 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.6', require: false

gem 'bootstrap', '~> 5.3.3'

gem 'sprockets-rails', '~> 3.5.1'

gem 'pg', '~> 1.2'

gem 'mutex_m'
gem 'bigdecimal'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.1', platforms: %i[mri mingw x64_mingw]
  gem 'debase', '~> 0.2.5.beta2'
  gem 'jasmine-rails', '~> 0.15.0'
  gem 'pry-byebug'
  gem 'ruby-debug-ide', '~> 0.7.0.beta6'
  gem 'xray-rails', '~> 0.3.2'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '~> 3.5'
  gem 'web-console', '>= 4.0.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 4.0'
gem 'spring-watcher-listen', '~> 2.1'

  # Performance monitoring
  gem 'bullet', '~> 7.0'

  gem 'pry-rails'
  gem 'puma'
end

group :heroku do
  gem 'sendgrid-ruby'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.35', '< 4.0'
  gem 'selenium-webdriver', '~> 4.0'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'webdrivers', '~> 5.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2021', platforms: %i[mingw mswin x64_mingw jruby]

gem 'loofah', '>= 2.12.0'
