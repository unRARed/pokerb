require_relative 'test_helper'

class IntegrationTest < PokerTest
  def test_integration
    game = Poker::Game.new
    10.times{ game.add_player }
    game.determine_button
  end
end
