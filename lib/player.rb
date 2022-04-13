module Poker
  class Player
    attr_accessor :state

    def initialize
      @state = { bankroll: 0, hole_cards: [] }
    end

    def adjust_bankroll(amount)
      @state = @state.merge(
        bankroll: (@state[:bankroll] + amount)
      )
    end

    def draw(card)
      @state = @state.merge(
        hole_cards: @state[:hole_cards] + [card]
      )
    end
  end
end
