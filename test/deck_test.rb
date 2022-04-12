require_relative 'test_helper'

class DeckTest < PokerTest
  let(:subject) { Poker::Deck.new }

  def test_initialize
    assert_equal(52, subject.state[:drawpile].size)
  end

  def test_burn
    burn_card = subject.state[:drawpile].first

    subject.burn

    assert_equal(51, subject.state[:drawpile].size)
    assert_equal(1, subject.state[:burnpile].size)
    assert_includes(subject.state[:burnpile], burn_card)

    next_burn = subject.state[:drawpile].first

    subject.burn

    assert_equal(50, subject.state[:drawpile].size)
    assert_equal(2, subject.state[:burnpile].size)
    assert_includes(subject.state[:burnpile], next_burn)
  end

  def test_shuffle
    original_drawpile = subject.state[:drawpile]
    subject.shuffle

    assert_equal(52, subject.state[:drawpile].size)
    assert_equal(0, subject.state[:burnpile].size)

    # TODO: test randomness on a large sample set
  end
end
