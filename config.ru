require 'bundler/setup'
Bundler.require(:default)
require './rbpkr'

map "/" do
  run RbPkr
end
