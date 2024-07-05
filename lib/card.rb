module Poker
  class Card
    attr_reader :suit, :rank

    RANKS = [
      '2', '3', '4', '5', '6', '7', '8', '9',
      'Ten', 'Jack', 'Queen', 'King', 'Ace'
    ].freeze
    SUITS = ["clubs", "diamonds", "hearts", "spades"].freeze

    BACKS = Dir.glob('./**/*Back.png').map do |path|
      path.split('/').last
    end

    def self.backs_for_select
      pairs = BACKS.map do |image|
        key = image.scan(/([A-Z].*)Back\.png/)
        { key.flatten.first => image }
      end
      pairs.reduce({}, :merge)
    end

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

    def tuple
      [rank, suit]
    end

    def name
      "#{rank} of #{suit}"
    end

    def absolute_value
      value(rank) + value(suit)
    end

    def game_value
      value(rank).to_i
    end

    def value(v)
      case v
      when "clubs"
        0.1
      when "diamonds"
        0.2
      when "hearts"
        0.3
      when "spades"
        0.4
      when /\d{1}/
        v.to_f
      when 'Ten'
        10.0
      when 'Jack'
        11.0
      when 'Queen'
        12.0
      when 'King'
        13.0
      when 'Ace'
        14.0
      else
        0.0
      end
    end

    def image
      "<img src='/assets/#{id}.png' alt='#{name}' width='140'>"
    end

  private

    def valid?
       RANKS.include?(rank) && SUITS.include?(suit)
    end
  end
end
