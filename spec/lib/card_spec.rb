require "spec_helper"

RSpec.describe "Card" do
  let(:subject) { Poker::Card.new }

  it ".initialize" do
    expect(subject.rank).not_to eq(nil)
    expect(subject.suit).not_to eq(nil)
  end

  context "class methods" do
    let(:subject) { Poker::Card }

    it ".backs_for_select" do
      images = Dir.glob("./images/**/*.png")
      subject.backs_for_select.values.each do |back|
        images.any?{|i| i.include?(back) }
      end
    end
  end

  it ".tuple" do
    card = Poker::Card.new("Ace", "hearts")
    expect(card.tuple).to eq([card.rank, card.suit])
  end

  it ".absolute_value" do
    card = Poker::Card.new("Ace", "hearts")
    expect(card.absolute_value).to eq(14.3)

    card = Poker::Card.new("8", "spades")
    expect(card.absolute_value).to eq(8.4)
  end

  it ".game_value" do
    card = Poker::Card.new("Ace", "hearts")
    expect(card.game_value).to eq(14)

    card = Poker::Card.new("4", "hearts")
    expect(card.game_value).to eq(4)
  end

  it ".value" do
    card = Poker::Card.new("Jack")
    expect(card.value("Jack")).to eq(11.0)
    expect(card.value("2")).to eq(2.0)
    expect(card.value("hearts")).to eq(0.3)
    expect(card.value("spades")).to eq(0.4)
  end
end
