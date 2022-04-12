require 'minitest/autorun'
require 'byebug'

Dir.glob(Dir.pwd + '/lib/**/*.rb').each do |file_path|
  require file_path
end

class PokerTest < Minitest::Test
  extend Minitest::Spec::DSL
end
