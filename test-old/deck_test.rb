require_relative 'test_helper'

class DeckTest < PokerTest
  let(:subject) { Poker::Deck.new }

  def test_initialize
    assert_equal(52, subject.state[:stack].size)
  end

  def test_burn
    burn_card = subject.state[:stack].first

    subject.burn

    assert_equal(51, subject.state[:stack].size)
    assert_equal(1, subject.state[:burnt].size)
    assert_includes(subject.state[:burnt], burn_card)

    next_burn = subject.state[:stack].first

    subject.burn

    assert_equal(50, subject.state[:stack].size)
    assert_equal(2, subject.state[:burnt].size)
    assert_includes(subject.state[:burnt], next_burn)
  end

  def test_draw
    drawn_card = subject.state[:stack].first

    subject.draw

    assert_equal(51, subject.state[:stack].size)
    assert_equal(1, subject.state[:drawn].size)
    assert_includes(subject.state[:drawn], drawn_card)

    next_draw = subject.state[:stack].first

    subject.draw

    assert_equal(50, subject.state[:stack].size)
    assert_equal(2, subject.state[:drawn].size)
    assert_includes(subject.state[:drawn], next_draw)
  end

  def test_shuffle
    original_stack = subject.state[:stack]
    subject.shuffle

    assert_equal(52, subject.state[:stack].size)
    assert_equal(0, subject.state[:burnt].size)
    assert_equal(0, subject.state[:drawn].size)

    # TODO: test randomness on a large sample set
  end

  def test_to_s
    assert_equal(
      "2c 3c 4c 5c 6c 7c 8c 9c Tc Jc Qc Kc Ac 2d 3d 4d 5d 6d 7d 8d 9d Td Jd Qd Kd Ad 2h 3h 4h 5h 6h 7h 8h 9h Th Jh Qh Kh Ah 2s 3s 4s 5s 6s 7s 8s 9s Ts Js Qs Ks As",
      subject.to_s
    )
  end
end
