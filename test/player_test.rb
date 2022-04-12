require_relative 'test_helper'

class PlayerTest < PokerTest
  let(:subject) { Poker::Player.new }

  def test_initialize
    assert_equal({ bankroll: 0 }, subject.state)
  end

  def test_adjust_bankroll
    assert_equal(subject.state[:bankroll], 0)
    subject.adjust_bankroll(1.1)
    assert_equal(subject.state[:bankroll], 1.1)
    subject.adjust_bankroll(-2.1)
    assert_equal(subject.state[:bankroll], -1)
  end
end
