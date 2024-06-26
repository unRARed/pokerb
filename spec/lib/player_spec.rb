require "spec_helper"

RSpec.describe "Player" do
  let(:subject) { Poker::Player.new }

  it "initialize" do
    expect(subject.hole_cards.size).to eq(0)
    expect(subject.name).to eq(nil)
    expect(subject.is_dealer).to eq(false)
  end

  it ".draw" do
    card = Poker::Card.new("Ace", :hearts)
    subject.draw(card)

    expect(subject.to_hash[:hole_cards].size).to eq(1)
    expect(subject.to_hash[:hole_cards].first).to eq(card.tuple)
  end

  it ".fold" do
    card = Poker::Card.new("Ace", :hearts)
    subject.draw(card)

    expect(subject.hole_cards.size).to eq(1)

    subject.fold

    expect(subject.hole_cards.size).to eq(0)
  end

  it ".holding" do
    board = [
      Poker::Card.new("2", :hearts),
      Poker::Card.new("3", :hearts),
      Poker::Card.new("7", :hearts),
      Poker::Card.new("5", :clubs),
      Poker::Card.new("9", :spades)
    ]

    subject.draw(Poker::Card.new("Ace", :hearts))
    subject.draw(Poker::Card.new("King", :hearts))

    expect(subject.holding(board).class).to eq(Poker::Holding)
    expect(subject.holding(board).best_hand[0]).to eq("a Flush")
  end
end
