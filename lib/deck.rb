require_relative 'card'
require_relative 'player'

module Poker
  class Deck
    attr_reader :state, :flopped, :phase

    def self.fresh
      stack = []
      Poker::Card::SUITS.each do |suit|
        Poker::Card::RANKS.each do |rank|
          stack << Poker::Card.new(rank, suit)
        end
      end
      stack
    end

    def initialize(state = {})
      @state = {
        stack: [], burnt: [], drawn: [],
        flopped: [], phase: :pre_flop
      }.merge(state)

      @phase = @state[:phase]
      @stack = @state[:stack].map{ |c| Poker::Card.new *c }
      @burnt = @state[:burnt].map{ |c| Poker::Card.new *c }
      @drawn = @state[:drawn].map{ |c| Poker::Card.new *c }
      @flopped = @state[:flopped].map{ |c| Poker::Card.new *c }
    end

    def reset
      puts "Resetting deck"
      @stack = Deck.fresh
      @burnt = []
      @drawn = []
      @flopped = []
      @phase = :pre_flop
    end

    def next_phase
      case @phase
      when :pre_flop
        @phase = :flop
      when :flop
        @phase = :turn
      when :turn
        @phase = :river
      when :river
        @phase = :pre_flop
      end
    end

    def advance
      # NOTE: assumes hole cards already dealt
      case @phase
      when :pre_flop
        turn_over(3)
        @phase = :flop
      when :flop
        turn_over
        @phase = :turn
      when :turn
        turn_over
        @phase = :river
      when :river
        reset
      end
    end

    def burn
      target = @stack[0]
      @stack = @stack - [target]
      @burnt << target
    end

    def turn_over(count = 1)
      burn
      count.times { @flopped << draw }
    end

    def draw
      puts "Drawing card"
      target = @stack[0]
      @stack = @stack - [target]
      @drawn << target
      target
    end

    def shuffle
      # Riffle shuffle between 4 and 6 times
      shuffle_count = (4..6).to_a.sample
      shuffle_count.times do |index|
        # before last riffle, box twice
        if index == shuffle_count - 1
          2.times{ @stack = box_shuffle(@stack) }
        end

        @stack = riffle_shuffle(@stack)
      end
    end

    def to_s
      @stack.map{ |c| c.id }.join(' ')
    end

    def to_hash
      {
        stack: @stack.map{ |c| c.tuple },
        burnt: @burnt.map{ |c| c.tuple },
        drawn: @drawn.map{ |c| c.tuple },
        flopped: @flopped.map{ |c| c.tuple },
        phase: @phase
      }
    end

    # def wash
    #   @state = @state.merge(
    #     stack: (@state[:stack] + @state[:burnt]).
    #       shuffle,
    #     burnt: []
    #   )
    # end

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
      right_hand
    end
  end
end
