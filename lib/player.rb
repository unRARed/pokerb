module Poker
  class Player
    attr_reader :state, :hole_cards, :name

    def initialize(state = {})
      @state = { name: nil, hole_cards: [] }.merge(state)
      @hole_cards = @state[:hole_cards].map{ |c| Poker::Card.new *c }
      @name = @state[:name]
    end

    def draw(card)
      @hole_cards = @hole_cards + [card]
    end

    def fold
      @hole_cards = []
    end

    def to_hash
      {
        name: @state[:name],
        hole_cards: @hole_cards.map{ |c| c.tuple }
      }
    end

    def reset
      @hole_cards = []
    end

    def holding(board)
      Poker::Holding.new @hole_cards + board
    end
  end
end
