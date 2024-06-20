# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-contrib', require: false
gem 'rackup'
gem "rqrcode", "~> 2.0"
gem "slim"
gem 'yaml'
gem 'puma'
gem "activesupport"

group :development do
  gem 'byebug'
end

group :test do
  gem 'webdrivers'
  gem "rspec"
  gem "capybara"
  gem "rack-test"
  gem 'simplecov'
end
