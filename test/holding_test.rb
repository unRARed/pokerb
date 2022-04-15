require_relative 'test_helper'

class HoldingTest < PokerTest
  def test_initialize_sorting
    five_h = Poker::Card.new('5', :hearts)
    three_s = Poker::Card.new('3', :spades)
    queen_d = Poker::Card.new('Queen', :diamonds)
    eight_c = Poker::Card.new('8', :clubs)
    holding = Poker::Holding.new(
      [five_h, three_s, queen_d, eight_c]
    )
    assert_equal(
      [queen_d, eight_c, five_h, three_s], holding.cards
    )
  end

  def test_straight?
    cards = [
      Poker::Card.new('3', :spades),
      Poker::Card.new('4', :clubs),
      Poker::Card.new('Ten', :spades),
      Poker::Card.new('Queen', :hearts),
      Poker::Card.new('5', :clubs),
      Poker::Card.new('6', :hearts),
      Poker::Card.new('7', :clubs),
      Poker::Card.new('3', :hearts)
    ]
    # 3,4,T,Q,5,6,7,3
    holding = Poker::Holding.new(cards)
    assert_equal true, holding.straight?
    # 3,4,T,Q,5,6,7
    holding = Poker::Holding.new(cards[0..-2])
    assert_equal true, holding.straight?
    # 3,4,T,Q,5,6
    holding = Poker::Holding.new(cards[0..-3])
    assert_equal false, holding.straight?
  end

  def test_flush?
    cards = [
      Poker::Card.new('3', :spades),
      Poker::Card.new('King', :spades),
      Poker::Card.new('Ten', :spades),
      Poker::Card.new('Queen', :hearts),
      Poker::Card.new('5', :spades),
      Poker::Card.new('6', :hearts),
      Poker::Card.new('7', :spades),
      Poker::Card.new('3', :hearts)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal true, holding.flush?
    # 3,4,T,Q,5,6,7
    holding = Poker::Holding.new(cards[0..-2])
    assert_equal true, holding.flush?
    # 3,4,T,Q,5,6
    holding = Poker::Holding.new(cards[0..-3])
    assert_equal false, holding.flush?
  end

  def test_straight_flush?
    cards = [
      Poker::Card.new('3', :spades),
      Poker::Card.new('4', :spades),
      Poker::Card.new('5', :spades),
      Poker::Card.new('6', :spades)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.straight_flush?
    # 3,4,T,Q,5,6,7
    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.flush?
    # 3,4,T,Q,5,6
    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :spades)])
    assert_equal true, holding.flush?
  end
end
