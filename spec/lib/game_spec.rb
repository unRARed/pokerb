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
    subject.add_player(Poker::Player.new(user_id: 1))
    expect(subject.players.size).to eq(1)

    subject.add_player(Poker::Player.new(user_id: 2))
    expect(subject.players.size).to eq(2)
  end

  it ".remove_player" do
    subject.add_player(Poker::Player.new(user_id: 3))
    expect(subject.players.size).to eq(1)

    subject.remove_player(3)
    expect(subject.players.size).to eq(0)
  end

  it ".determine_button" do
    expect(subject.button_index).to eq(nil)

    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))

    subject.determine_button

    expect(subject.button_index).to be_a(Integer)
  end

  it ".is_ready?" do
    expect(subject.is_ready?).to eq(false)

    subject.add_player(Poker::Player.new(user_id: 1))
    expect(subject.is_ready?).to eq(false)

    subject.add_player(Poker::Player.new(user_id: 2))
    expect(subject.is_ready?).to eq(false)

    subject.determine_button
    expect(subject.is_ready?).to eq(true)
  end

  it ".move_button" do
    subject = Poker::Game.new(is_fresh: true, button_index: 0)

    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))

    subject.move_button
    expect(subject.button_index).to eq(1)

    subject.move_button
    expect(subject.button_index).to eq(2)

    subject.move_button
    expect(subject.button_index).to eq(0)
  end

  it ".players_in_turn_order" do
    pending "Need to implement"
    fail
    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))

    subject.determine_button
  end
end
