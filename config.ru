require 'bundler/setup'
Bundler.require(:default)
require './pokerb'

map "/" do
  run PokeRb
end
