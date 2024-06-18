require_relative 'player'
require_relative 'deck'
require_relative 'hand'
require 'securerandom'
require 'rqrcode'

module Poker
  class Game
    attr_reader :state, :deck, :players, :all_cards

    def initialize(state = {})
      @state = {
        id: SecureRandom.
          base64.gsub(/[^a-zA-Z]/, '')[0..3].upcase,
        manager: "",
        password: "",
        step_color: "#ffffff",
        url: "https://example.com",
        players: [],
        hands: [],
        deck: {},
        card_back: "DefaultBack.png",
        button_index: nil,
        is_fresh: false
      }.merge(state)

      if @state[:is_fresh]
        @deck = Poker::Deck.
          new stack: Deck.fresh.map{ |c| c.tuple }
        @state[:is_fresh] = false
      else
        @deck = Poker::Deck.new @state[:deck]
      end
      @players = @state[:players].map{ |p| Poker::Player.new p }

      puts "Game #{@state[:id]} initialized"
      puts "Players: #{players.map(&:state).map{ |p| p[:name] }}"

      unless @state[:is_fresh]
        raise if all_cards.size != 52
        raise if all_cards.uniq.length != all_cards.length
      end
    end

    def has_password?
      !@state[:password].nil? && @state[:password].size > 0
    end

    def all_cards
      (@deck.all_cards + @players.map(&:hole_cards).flatten)
    end

    def rand_color
      "##{SecureRandom.hex(3)}"
    end

    def is_manager?(player_name)
      @state[:manager] == player_name
    end

    def is_common_phase?
      [:flop, :turn, :river].include? @deck.phase
    end

    def is_playing?(player_name)
      @state[:players].any?{ |p| p[:name] == player_name }
    end

    def has_cards?(player_name)
      player_by_name(player_name).state[:hole_cards].size > 0
    end

    def player_by_name(player_name)
      @players.find{ |p| p.state[:name] == player_name }
    end

    def to_hash
      @state.merge(
        deck: deck.to_hash,
        players: @players.map(&:to_hash)
      )
    end

    def qr_code
      RQRCode::QRCode.new @state[:url] + "/games/#{@state[:id]}"
    end

    def advance
      puts "Advancing game"
      case @deck.phase
      when :deal
        deal
        @deck.advance
      when :river
        @players.each{ |player| @deck.discard(player.reset) }
        @deck.reset
        @deck.advance
      else
        @deck.advance
      end
      # set color for the next step, so folks can know
      # if their client is up to date
      @state = @state.merge(step_color: rand_color)
    end

    def determine_button
      @state[:deck].wash
      @players.each do |player|
        player.draw(@deck.draw)
      end
      winner = @players.max do |a,b|
        a.state[:hole_cards].sum(&:full_value) <=> b.
          state[:hole_cards].sum(&:full_value)
      end
      @state = @state.merge(
        button_index: @players.index(winner)
      )
    end

    def add_player(player = Poker::Player.new({}))
      puts "Adding player #{player.state[:name]}"
      raise ArgumentError, 'Game is full' if @players.size >= 10
      if @players.any?{|p| p.state[:name] == player.state[:name] }
        raise ArgumentError,
          "The User Name '#{player.state[:name]}' is taken."
      end
      @players << player
    end

    def remove_player(player_name)
      if (player = @players.
        find{|p| p.state[:name] == player_name }
      )
        @players.delete(player)
      end
      player
    end

    def ready?
      @players.size > 1 && @state[:button_index]
    end

    def players_in_turn_order
      @players[(@state[:button_index] + 1)..-1] +
      @players[0..@state[:button_index]]
    end

    def dealer
      players_in_turn_order[-1]
    end

    def player_in_small_blind
      players_in_turn_order[0]
    end

    def player_in_big_blind
      players_in_turn_order[1]
    end

    # def deal(hand = Poker::Hand.new)
    def deal
      2.times do
        @players.each do |player|
          player.draw(@deck.draw)
        end
      end
    end
  end
end
