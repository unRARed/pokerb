module Poker
  class Player
    attr_accessor :state

    def initialize
      @state = { chip_count: 0, hole_cards: [] }
    end

    def adjust_chip_count(amount)
      @state = @state.merge(
        chip_count: (@state[:chip_count] + amount)
      )
    end

    def draw(card)
      @state = @state.merge(
        hole_cards: @state[:hole_cards] + [card]
      )
    end

    # def holding
    #   Poker::Holding.new @state[:hole_cards]
    # end
  end
end
