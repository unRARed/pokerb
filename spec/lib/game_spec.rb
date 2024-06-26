require "spec_helper"

RSpec.describe "Game" do
  let(:subject) { Poker::Game.new(is_fresh: true) }

  it ".initialize" do
    expect(subject.players.size).to eq(0)
    expect(subject.deck.state[:stack].size).to eq(52)
    expect(subject.deck.state[:discarded].size).to eq(0)
    expect(subject.deck.state[:community].size).to eq(0)
    expect(subject.deck.phase).to eq(:deal)
  end

  it ".add_player" do
    subject.add_player(Poker::Player.new(name: "Foo"))
    expect(subject.players.size).to eq(1)

    subject.add_player(Poker::Player.new(name: "Bar"))
    expect(subject.players.size).to eq(2)
  end

  it ".remove_player" do
    subject.add_player(Poker::Player.new(name: "Foo"))
    expect(subject.players.size).to eq(1)

    subject.remove_player("Foo")
    expect(subject.players.size).to eq(0)
  end

  it ".determine_button" do
    expect(subject.button_index).to eq(nil)

    subject.add_player(Poker::Player.new(name: "Foo"))
    subject.add_player(Poker::Player.new(name: "Bar"))

    subject.determine_button

    expect(subject.button_index).to be_a(Integer)
  end

  it ".ready?" do
    expect(subject.ready?).to eq(false)

    subject.add_player(Poker::Player.new(name: "Foo"))
    expect(subject.ready?).to eq(false)

    subject.add_player(Poker::Player.new(name: "Bar"))
    expect(subject.ready?).to eq(false)

    subject.determine_button
    expect(subject.ready?).to eq(true)
  end

  it ".move_button" do
    subject = Poker::Game.new(is_fresh: true, button_index: 0)

    subject.add_player(Poker::Player.new(name: "Foo"))
    subject.add_player(Poker::Player.new(name: "Bar"))
    subject.add_player(Poker::Player.new(name: "Baz"))

    subject.move_button
    expect(subject.button_index).to eq(1)

    subject.move_button
    expect(subject.button_index).to eq(2)

    subject.move_button
    expect(subject.button_index).to eq(0)
  end

  it ".players_in_turn_order" do
    subject.add_player(Poker::Player.new(name: "Foo"))
    subject.add_player(Poker::Player.new(name: "Bar"))
    subject.add_player(Poker::Player.new(name: "Baz"))

    subject.determine_button

    puts ''
  end
end
