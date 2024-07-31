require "spec_helper"

RSpec.describe "Game" do
  let(:subject) do
    Poker::Game.new(
      Poker::Deck.new(
        stack: Poker::Deck.fresh.map{ |c| c.tuple }
      ).to_hash.merge(is_fresh: true)
    )
  end

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
    subject = Poker::Game.new(is_fresh: true, button_index: 0)
    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))
    subject.add_player(Poker::Player.new(user_id: 4))
    subject.add_player(Poker::Player.new(user_id: 5))

    # brute force player 3 to be the current dealer
    subject.instance_variable_set(:@button_index, 2)

    # player after the dealer is first (4th player)
    expect(subject.players_in_turn_order.first).
      to eq(subject.players[3])

    # dealer is last
    expect(subject.players_in_turn_order.last).
      to eq(subject.players[2])
  end

  it ".dealer" do
    subject = Poker::Game.new(is_fresh: true, button_index: 1)

    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))

    # dealer is the second player per the button index
    expect(subject.dealer).not_to eq(subject.players[0])
    expect(subject.dealer).to eq(subject.players[1])
    expect(subject.dealer).not_to eq(subject.players[2])
  end

  it ".player_in_small_blind" do
    subject = Poker::Game.new(is_fresh: true, button_index: 1)

    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))

    # small blind is the third player per the button index
    expect(subject.player_in_small_blind).not_to eq(subject.players[0])
    expect(subject.player_in_small_blind).not_to eq(subject.players[1])
    expect(subject.player_in_small_blind).to eq(subject.players[2])
  end

  it ".player_in_big_blind" do
    subject = Poker::Game.new(is_fresh: true, button_index: 1)

    subject.add_player(Poker::Player.new(user_id: 1))
    subject.add_player(Poker::Player.new(user_id: 2))
    subject.add_player(Poker::Player.new(user_id: 3))

    # big blind is the first player (wraps) per the button index
    expect(subject.player_in_big_blind).to eq(subject.players[0])
    expect(subject.player_in_big_blind).not_to eq(subject.players[1])
    expect(subject.player_in_big_blind).not_to eq(subject.players[2])
  end
end
