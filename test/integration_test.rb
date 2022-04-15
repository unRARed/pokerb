require_relative 'test_helper'

class IntegrationTest < PokerTest
  def test_integration
    game = Poker::Game.new
    puts 'ADD PLAYERS'
    10.times{ game.add_player }
    puts 'DETERMINE BUTTON'
    game.determine_button
    puts 'DEAL'
    game.deal
    puts game.state[:button_index]
  end
end
