require_relative 'card'
require_relative 'player'

module Poker
  class Deck
    attr_accessor :state

    def initialize
      @state = { stack: [], burnt: [], drawn: [] }

      Poker::Card::SUITS.each do |suit|
        Poker::Card::VALUES.each do |value|
          @state = @state.merge(
            stack: @state[:stack] + [
              Poker::Card.new(value: value, suit: suit)
            ]
          )
        end
      end
    end

    def burn
      target = @state[:stack][0]
      @state = @state.merge(
        stack: @state[:stack][1..-1],
        burnt: @state[:burnt] + [target]
      )
    end

    def draw
      target = @state[:stack][0]
      @state = @state.merge(
        stack: @state[:stack][1..-1],
        drawn: @state[:drawn] + [target]
      )
      target
    end

    def shuffle
      cards = @state[:stack] + @state[:burnt]

      # now Riffle shuffle between 4 and 6 times
      shuffle_count = (4..6).to_a.sample
      shuffle_count.times do |index|
        # before last riffle, box twice
        if index == shuffle_count - 1
          2.times{ cards = box_shuffle(cards) }
        end

        cards = riffle_shuffle(cards)
      end
      @state = @state.merge(stack: cards, burnt: [])
    end

    def to_s
      @state[:stack].
        map{ |c| c.value[:name][0] + c.suit[:name][0] }.
        join(' ')
    end

    def wash
      @state = @state.merge(
        stack: (@state[:stack] + @state[:burnt]).
          shuffle,
        burnt: []
      )
      puts 'Washed'
    end

  private

    def riffle_shuffle(cards)
      is_left_hand = false
      left_hand = cards[0..(25..35).to_a.sample]
      right_hand = cards - left_hand
      cards = []
      until left_hand.empty? || right_hand.empty?
        is_left_hand = !is_left_hand
        slice = (1..10).to_a.sample

        cards = is_left_hand ?
          cards + left_hand[0..slice] :
          cards + right_hand[0..slice]
        is_left_hand ?
          left_hand = left_hand - cards :
          right_hand = right_hand - cards
      end

      puts 'Riffled'
      cards + (
        left_hand.empty? ?
          right_hand : left_hand
      )
    end

    def box_shuffle(cards)
      left_hand = cards
      right_hand = []
      until left_hand.empty?
        slice = (5..15).to_a.sample
        right_hand = right_hand + left_hand[0..slice].reverse
        left_hand = left_hand - right_hand
      end
      puts 'Boxed'
      right_hand
    end
  end
end
