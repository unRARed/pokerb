module Poker
  class Card
    attr_reader :suit, :rank

    RANKS = [
      '2', '3', '4', '5', '6', '7', '8', '9',
      'Ten', 'Jack', 'Queen', 'King', 'Ace'
    ].freeze
    SUITS = [
      :clubs, :diamonds, :hearts, :spades
    ].freeze

    def initialize(
      rank = RANKS.sample, suit = SUITS.sample
    )
      @rank = rank
      @suit = suit
      raise ArgumentError, 'Not a valid card' unless valid?
    end

    def id
      rank[0] + suit.to_s[0]
    end

    def name
      "#{rank} of #{suit}"
    end

    def full_value
      value(rank) + value(suit)
    end

    def value(v)
      case v
      when :clubs
        0.1
      when :diamonds
        0.2
      when :hearts
        0.3
      when :spades
        0.4
      when /\d{1}/
        v.to_i
      when 'Ten'
        10
      when 'Jack'
        11
      when 'Queen'
        12
      when 'King'
        13
      when 'Ace'
        14
      else
        0
      end
    end

  private

    def valid?
       RANKS.include?(rank) && SUITS.include?(suit)
    end
  end
end
