module Poker
  class Player
    attr_reader :state, :hole_cards, :user_id, :is_dealer

    def initialize(state = {})
      @state = { user_id: nil, hole_cards: [] }.merge(state)
      @hole_cards = @state[:hole_cards].
        map{ |c| Poker::Card.new *c }
      @user_id = @state[:user_id]
      @is_dealer = @state[:is_dealer] || false
    end

    def name
      return "" unless (@user_id.present? && @user_id > 0)
      User.find_by(id: @user_id)&.name || "Anonymous"
    end

    def draw(card)
      @hole_cards = @hole_cards + [card]
    end

    def fold
      cards = @hole_cards
      @hole_cards = []
      cards
    end

    def to_hash
      {
        user_id: @user_id,
        hole_cards: @hole_cards.map{ |c| c.tuple }
      }
    end

    def reset
      fold
    end

    def holding(board)
      Poker::Holding.new @hole_cards + board
    end
  end
end
