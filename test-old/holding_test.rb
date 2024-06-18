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

    holding = Poker::Holding.new(cards)
    assert_equal true, holding.straight?[0]

    holding = Poker::Holding.new(cards[0..-2])
    assert_equal true, holding.straight?[0]

    holding = Poker::Holding.new(cards[0..-3])
    assert_equal false, holding.straight?[0]
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
    assert_equal true, holding.flush?[0]

    holding = Poker::Holding.new(cards[0..-2])
    assert_equal true, holding.flush?[0]

    holding = Poker::Holding.new(cards[0..-3])
    assert_equal false, holding.flush?[0]
  end

  def test_straight_flush?
    cards = [
      Poker::Card.new('3', :spades),
      Poker::Card.new('4', :spades),
      Poker::Card.new('5', :spades),
      Poker::Card.new('6', :spades)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.straight_flush?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.straight_flush?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :spades)])
    assert_equal true, holding.straight_flush?[0]
  end

  def test_quads?
    cards = [
      Poker::Card.new('3', :hearts),
      Poker::Card.new('3', :diamonds),
      Poker::Card.new('3', :spades),
      Poker::Card.new('6', :spades)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.quads?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.quads?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('3', :clubs)])
    assert_equal true, holding.quads?[0]
  end

  def test_boat?
    cards = [
      Poker::Card.new('3', :hearts),
      Poker::Card.new('3', :diamonds),
      Poker::Card.new('3', :clubs),
      Poker::Card.new('6', :hearts)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.boat?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.boat?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('6', :clubs)])
    assert_equal true, holding.boat?[0]
  end

  def test_set?
    cards = [
      Poker::Card.new('3', :hearts),
      Poker::Card.new('3', :diamonds)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.set?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.set?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('3', :clubs)])
    assert_equal true, holding.set?[0]
  end

  def test_two_pair?
    cards = [
      Poker::Card.new('3', :hearts),
      Poker::Card.new('3', :diamonds),
      Poker::Card.new('5', :clubs),
      Poker::Card.new('6', :hearts)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.two_pair?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', :hearts)])
    assert_equal false, holding.two_pair?[0]

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('6', :clubs)])
    assert_equal true, holding.two_pair?[0]
  end

  def test_pair?
    cards = []
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.pair?[0]

    cards = cards + [Poker::Card.new('7', :hearts)]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.pair?[0]

    cards = cards + [Poker::Card.new('4', :diamonds)]
    holding = Poker::Holding.new(cards)
    assert_equal false, holding.pair?[0]

    cards = cards + [Poker::Card.new('7', :clubs)]
    holding = Poker::Holding.new(cards)
    assert_equal true, holding.pair?[0]
  end

  def test_best_hand
    cards = [
      Poker::Card.new('3', :hearts),
      Poker::Card.new('3', :diamonds)
    ]
    holding = Poker::Holding.new(cards)
    assert_equal 'a Pair', holding.best_hand[0]

    cards = cards + [Poker::Card.new('3', :clubs)]
    holding = Poker::Holding.new(cards)
    assert_equal 'a Set', holding.best_hand[0]

    cards = cards + [Poker::Card.new('3', :spades)]
    holding = Poker::Holding.new(cards)
    assert_equal 'Quads', holding.best_hand[0]
  end
end
