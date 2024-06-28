require_relative 'card'
require_relative 'player'
require_relative "../debug"

module Poker
  class Deck
    attr_reader :state, :community, :phase, :all_cards

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
        stack: [], discarded: [],
        community: [], phase: :deal
      }.merge(state)

      @phase = @state[:phase]
      [:stack, :discarded, :community].each do |key|
        instance_variable_set("@#{key}",
          @state[key].map!{ |c| Poker::Card.new *c }
        )
      end

      raise if all_cards.uniq.length != all_cards.length
    end

    def all_cards
      @stack + @discarded + @community
    end

    def reset
      Debug.this "Resetting deck"
      @stack = all_cards
      @discarded = []
      @community = []
      shuffle
    end

    def next_phase
      case @phase
      when :deal
        :pre_flop
      when :pre_flop
        :flop
      when :flop
        :turn
      when :turn
        :river
      else
        :deal
      end
    end

    def advance
      # NOTE: assumes hole cards already dealt
      case @phase
      when :deal
        @phase = :pre_flop
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
        @phase = :deal
      end
    end

    def burn
      # take card from top of deck
      target = @stack[@stack.length - 1]
      @stack = @stack - [target]
      @discarded << target
    end

    def turn_over(count = 1)
      burn
      count.times { @community << draw }
    end

    def draw
      Debug.this "Drawing card"
      # take card from top of deck
      target = @stack[@stack.length - 1]
      @stack = @stack - [target]
      target
    end

    def discard(cards)
      @discarded = @discarded + cards
    end

    def wash
      unless all_cards.count == 52
        raise ArgumentError, 'Incomplete Deck'
      end
      old_stack = all_cards
      new_stack = []

      while old_stack.length > 0
        new_stack << old_stack.delete_at(rand(old_stack.length))
      end
      @state = {
        stack: new_stack, discarded: [], community: []
      }.merge(state)
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
        discarded: @discarded.map{ |c| c.tuple },
        community: @community.map{ |c| c.tuple },
        phase: @phase
      }
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
