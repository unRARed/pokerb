# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'byebug'
gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-contrib', require: false
gem 'rackup'
gem 'minitest'
gem 'simplecov'
gem "rqrcode", "~> 2.0"
gem "foreman"
gem "slim"
gem 'yaml'
gem 'puma'
gem "activesupport"

group :test do
  gem "rspec"
  gem "capybara"
  gem "rack-test"
end
