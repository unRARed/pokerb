require_relative 'player'

module Poker
  class Game
    attr_accessor :state

    def initialize
      @state = {
        players: []
      }
    end

    def add_player(player = Poker::Player.new)
      @state = @state.
        merge(players: @state[:players] + [player])
    end
  end
end
