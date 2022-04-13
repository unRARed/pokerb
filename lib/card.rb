module Poker
  class Card
    attr_reader :suit, :value

    VALUES = [
      { name: '2', value: 2 },
      { name: '3', value: 3 },
      { name: '4', value: 4 },
      { name: '5', value: 5 },
      { name: '6', value: 6 },
      { name: '7', value: 7 },
      { name: '8', value: 8 },
      { name: '9', value: 9 },
      { name: 'Ten', value: 10 },
      { name: 'Jack', value: 11 },
      { name: 'Queen', value: 12 },
      { name: 'King', value: 13 },
      { name: 'Ace', value: 14 }
    ].freeze
    SUITS = [
      { name: :clubs, value: 0.1 },
      { name: :diamonds, value: 0.2 },
      { name: :hearts, value: 0.3 },
      { name: :spades, value: 0.4 }
    ].freeze

    def initialize(value: VALUES.sample, suit: SUITS.sample)
      @value = value
      @suit = suit
      raise ArgumentError, 'Not a valid card' unless valid?
    end

    def full_value
      @value[:value] + @suit[:value]
    end

  private

    def valid?
       VALUES.include?(value) && SUITS.include?(suit)
    end
  end
end
