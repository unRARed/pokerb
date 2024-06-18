require_relative 'test_helper'

class PlayerTest < PokerTest
  let(:subject) { Poker::Player.new }

  def test_initialize
    assert_equal(
      { chip_count: 0, hole_cards: [] }, subject.state
    )
  end

  def test_adjust_chip_count
    assert_equal(subject.state[:chip_count], 0)
    subject.adjust_chip_count(1.1)
    assert_equal(subject.state[:chip_count], 1.1)
    subject.adjust_chip_count(-2.1)
    assert_equal(subject.state[:chip_count], -1)
  end
end
