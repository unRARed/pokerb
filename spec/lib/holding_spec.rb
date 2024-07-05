require "spec_helper"

RSpec.describe "Holding" do
  let(:subject) { Poker::Holding.new }

  it ".initialize" do
    five_h = Poker::Card.new('5', "hearts")
    three_s = Poker::Card.new('3', "spades")
    queen_d = Poker::Card.new('Queen', "diamonds")
    eight_c = Poker::Card.new('8', "clubs")
    holding = Poker::Holding.new(
      [five_h, three_s, queen_d, eight_c]
    )

    expect(holding.cards).to eq([queen_d, eight_c, five_h, three_s])
  end

  it ".best_hand" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('3', "diamonds")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.best_hand[0]).to eq("a Pair")

    cards = cards + [Poker::Card.new('7', "hearts")]
    holding = Poker::Holding.new(cards)
    expect(holding.best_hand[0]).to eq("a Pair")

    cards = cards + [Poker::Card.new('3', "clubs")]
    holding = Poker::Holding.new(cards)
    expect(holding.best_hand[0]).to eq("Three of a Kind")

    cards = cards + [Poker::Card.new('7', "spades")]
    holding = Poker::Holding.new(cards)
    expect(holding.best_hand[0]).to eq("a Full House")
  end

  it ".pair?" do
    cards = []
    holding = Poker::Holding.new(cards)
    expect(holding.pair?[0]).to eq(false)

    cards = cards + [Poker::Card.new('7', "hearts")]
    holding = Poker::Holding.new(cards)
    expect(holding.pair?[0]).to eq(false)

    cards = cards + [Poker::Card.new('4', "diamonds")]
    holding = Poker::Holding.new(cards)
    expect(holding.pair?[0]).to eq(false)

    cards = cards + [Poker::Card.new('7', "clubs")]
    holding = Poker::Holding.new(cards)
    expect(holding.pair?[0]).to eq(true)
  end

  it ".two_pair?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('3', "diamonds"),
      Poker::Card.new('5', "clubs"),
      Poker::Card.new('6', "hearts")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.two_pair?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', "hearts")])
    expect(holding.two_pair?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('6', "clubs")])
    expect(holding.two_pair?[0]).to eq(true)
  end

  it ".set?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('3', "diamonds")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.set?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', "hearts")])
    expect(holding.set?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('3', "clubs")])
    expect(holding.set?[0]).to eq(true)
  end

  it ".full_house?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('3', "diamonds"),
      Poker::Card.new('3', "clubs"),
      Poker::Card.new('6', "hearts"),
      Poker::Card.new('6', "clubs")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.full_house?[0]).to eq(true)
  end

  it ".quads?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('3', "diamonds"),
      Poker::Card.new('3', "clubs")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.quads?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('7', "hearts")])
    expect(holding.quads?[0]).to eq(false)

    holding = Poker::Holding.
      new(cards + [Poker::Card.new('3', "clubs")])
    expect(holding.quads?[0]).to eq(true)
  end

  it ".straight?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('4', "diamonds"),
      Poker::Card.new('5', "clubs"),
      Poker::Card.new('6', "hearts"),
      Poker::Card.new('7', "clubs")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.straight?[0]).to eq(true)
  end

  it ".flush?" do
    cards = [
      Poker::Card.new('2', "hearts"),
      Poker::Card.new('4', "hearts"),
      Poker::Card.new('6', "hearts"),
      Poker::Card.new('8', "hearts"),
      Poker::Card.new('Ten', "hearts")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.flush?[0]).to eq(true)
  end

  it ".straight_flush?" do
    cards = [
      Poker::Card.new('3', "hearts"),
      Poker::Card.new('4', "hearts"),
      Poker::Card.new('5', "hearts"),
      Poker::Card.new('6', "hearts"),
      Poker::Card.new('7', "hearts")
    ]
    holding = Poker::Holding.new(cards)
    expect(holding.flush?[0]).to eq(true)
    expect(holding.straight_flush?[0]).to eq(true)
  end
end
