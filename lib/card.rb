module Poker
  class Card
    attr_reader :suit, :value

    VALUES = [
      # Ace could be 1 or 14
      { name: 'Ace' },
      { name: 'Deuce', value: 2 },
      { name: 'Three', value: 3 },
      { name: 'Four', value: 4 },
      { name: 'Five', value: 5 },
      { name: 'Six', value: 6 },
      { name: 'Seven', value: 7 },
      { name: 'Eight', value: 8 },
      { name: 'Nine', value: 9 },
      { name: 'Ten', value: 10 },
      { name: 'Jack', value: 11 },
      { name: 'Queen', value: 12 },
      { name: 'King', value: 13 }
    ].freeze
    SUITS = [:clubs, :diamonds, :hearts, :spades].freeze

    def initialize(value: VALUES.sample, suit: SUITS.sample)
      @value = value
      @suit = suit
      raise ArgumentError, 'Not a valid card' unless valid?
    end

  private
    def valid?
       VALUES.include?(value) && SUITS.include?(suit)
    end
  end
end
