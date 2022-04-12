require_relative 'test_helper'

class GameTest < PokerTest
  let(:subject) { Poker::Game.new }

  def test_initialize
    assert_equal({ players: [] }, subject.state)
  end

  def test_add_player
    subject.add_player
    assert_equal 1, subject.state[:players].size
  end

  # TODO: determine how to target player
  # def test_remove_player
  # end
end
