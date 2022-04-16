module Poker
  class Holding
    attr_reader :cards

    # cards is hole_cards + the board
    def initialize(cards)
      @cards = cards.sort_by(&:full_value)&.reverse || []
    end

    def best_hand
      check, result = straight_flush?
      return ['Straight Flush', result] if check
      check, result = quads?
      return ['Quads', result] if check
      check, result = boat?
      return ['Boat', result] if check
      check, result = flush?
      return ['Flush', result] if check
      check, result = straight?
      return ['Straight', result] if check
      check, result = set?
      return ['Set', result] if check
      check, result = two_pair?
      return ['Two Pair', result] if check
      check, result = pair?
      return ['Pair', result] if check
    end

    def straight_flush?
      return [false, []] unless @cards.size > 4
      flush_result = flush?[1]
      return [false, []] unless flush_result.present?
      straight_result = _get_straight(flush_result)
      return [false, []] unless straight_result.present?
      [true, straight_result]
    end

    def quads?
      return [false, []] unless @cards.size > 3
      result = cards.
        group_by{|c| c.value(c.rank) }.
        find{|_, v| v.size > 3 }
      return [false, []] unless result.present?
      [true, result[1]]
    end

    def boat?
      return [false, []] unless @cards.size > 4
      return [false, []] unless (
        set = cards.
          group_by{|c| c.value(c.rank) }.
          find{|_, v| v.size > 2 }
      )
      pair = _get_pair(cards - set[1])
      return [false, []] unless pair.present?
      [true, set[1] + pair]
    end

    def flush?
      return [false, []] unless @cards.size > 4
      Poker::Card::SUITS.each do |suit|
        next unless group = @cards.group_by(&:suit)[suit]
        return [true, group] if group.count > 4
      end
      [false, []]
    end

    def straight?
      return [false, []] unless @cards.size > 4

      result = _get_straight(@cards)
      return [false, []] unless result.present?
      [true, result]
    end

    def set?
      return [false, []] unless @cards.size > 2
      result = cards.
        group_by{|c| c.value(c.rank) }.
        find{|_, v| v.size > 2 }
      return [false, []] unless result.present?
      [true, result[1]]
    end

    def two_pair?
      return [false, []] unless @cards.size > 3
      first_pair = _get_pair(cards)
      return [false, []] unless first_pair.present?
      second_pair = _get_pair(@cards - first_pair)
      return [false, []] unless second_pair.present?
      [true, second_pair]
    end

    def pair?
      return [false, []] unless @cards.size > 1
      pair = _get_pair(cards)
      return [false, []] unless pair.present?
      [true, pair]
    end

  private

    def _get_pair(cards)
      group = cards.group_by{|c| c.value(c.rank) }.
        find{|_, v| v.size > 1 }
      return [] unless group.present?
      group[1]
    end

    def _get_straight(cards)
      last = cards[0]
      straight = [last]
      cards.each_with_index do |card, i|
        next if i == 0
        if (
          last.full_value.floor - card.full_value.floor
        ) == 1
          straight = straight + [card]
        else
          straight = [card]
        end
        return straight if straight.size == 5
        last = card
      end
      []
    end
  end
end
