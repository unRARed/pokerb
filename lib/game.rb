require_relative 'player'
require_relative 'deck'
require_relative 'hand'

module Poker
  class Game
    attr_accessor :state

    def initialize
      @state = {
        deck: Poker::Deck.new,
        players: [],
        hands: [],
        button_index: nil
      }
    end

    def determine_button
      @state[:deck].wash
      @state[:players].each do |player|
        player.draw(@state[:deck].draw)
      end
      winner = @state[:players].max do |a,b|
        a.state[:hole_cards].sum(&:full_value) <=> b.
          state[:hole_cards].sum(&:full_value)
      end
      @state = @state.merge(
        button_index: @state[:players].index(winner)
      )
    end

    def add_player(player = Poker::Player.new)
      raise ArgumentError, 'Game is full' if @state[:players].size > 10
      @state = @state.
        merge(players: @state[:players] + [player])
    end

    def ready?
      @state[:players].size > 1 && @state[:button_index]
    end

    def players_in_turn_order
      @state[:players][(@state[:button_index] + 1)..-1] +
      @state[:players][0..@state[:button_index]]
    end

    def dealer
      players_in_turn_order[-1]
    end

    def player_in_small_blind
      players_in_turn_order[0]
    end

    def player_in_big_blind
      players_in_turn_order[1]
    end

    # def deal(hand = Poker::Hand.new)
    def deal
      @state[:deck].shuffle
      2.times do
        @state[:players].each do |player|
          player.draw(@state[:deck].draw)
        end
      end
    end
  end
end
