module Poker
  class Holding
    attr_reader :cards

    # cards is hole_cards + the board
    def initialize(cards)
      @cards = cards.sort_by(&:full_value).reverse
    end

    def straight_flush?
      return false unless @cards.size > 4
      straight? && flush?
    end

    # def quads?
    #   return false unless @cards.size > 3
    # end
    # def boat?
    #   return false unless @cards.size > 4
    # end

    def flush?
      return false unless @cards.size > 4

      Poker::Card::SUITS.each do |suit|
        next unless @cards.group_by(&:suit)[suit]
        return true if @cards.group_by(&:suit)[suit].count > 4
      end
      false
    end

    def straight?
      return false unless @cards.size > 4

      last = @cards[0]
      straight = []
      @cards.each_with_index do |card, i|
        next if i == 0
        if (
          last.full_value.floor - card.full_value.floor
        ) == 1
          straight = straight + [card]
        else
          straight = [card]
        end
        return true if straight.size == 5
        last = card
      end
      false
    end

    # def set?
    #   return false unless @cards.size > 2
    # end
    # def two_pair?
    #   return false unless @cards.size > 3
    # end
    # def pair?
    # end

  end
end
