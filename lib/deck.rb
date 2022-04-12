require_relative 'card'

module Poker
  class Deck
    attr_accessor :state

    def initialize
      @state = { drawpile: [], burnpile: [] }

      Poker::Card::SUITS.each do |suit|
        Poker::Card::VALUES.each do |value|
          @state = @state.merge(
            drawpile: @state[:drawpile] + [
              Poker::Card.new(value: value, suit: suit)
            ]
          )
        end
      end
    end

    def burn
      target = @state[:drawpile][0]
      @state = @state.merge(
        drawpile: @state[:drawpile][1..-1],
        burnpile: @state[:burnpile] + [target]
      )
    end

    def shuffle
      unless @state[:drawpile].size == 52
        raise StandardError, 'Cannot shuffle after drawing'
      end

      # TODO: move the burnpile to drawpile here

      # First "wash the cards" with built-in method
      cards = @state[:drawpile].shuffle

      # now Riffle shuffle 5-8 times
      (5..8).to_a.sample.times do
        is_left = false
        left = cards[0..(25..35).to_a.sample]
        right = cards - left
        cards = []
        until left.empty? || right.empty? do
          is_left = !is_left
          slice = (1..10).to_a.sample

          cards = is_left ?
            cards + left[0..slice] :
            cards + right[0..slice]
          is_left ?
            left = left - cards :
            right = right - cards
        end

        cards = cards + (
          left.empty? ?
            right : left
        )

        # TODO: Add 1 box shuffle before the last riffle
      end
      @state = @state.merge(drawpile: cards, burnpile: [])
    end
  end
end
