require_relative 'player'
require_relative 'deck'
require_relative 'hand'
require 'securerandom'
require 'rqrcode'
require_relative '../debug'

module Poker
  class Game
    attr_reader :state,
      :deck,
      :players,
      :all_cards,
      :dealer,
      :button_index,
      :manager

    def initialize(state = {})
      @state = {
        id: SecureRandom.
          base64.gsub(/[^a-zA-Z]/, '')[0..3].upcase,
        manager_id: nil,
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
        @state[:created_at] = Time.now.to_i
      else
        @deck = Poker::Deck.new @state[:deck]
      end
      @players = @state[:players].map{ |p| Poker::Player.new p }
      @button_index = @state[:button_index]

      Debug.this "Game #{@state[:id]} initialized"
      Debug.this "Players: #{players.map(&:state).map{ |p| p[:name] }}"

      unless @state[:is_fresh]
        raise ArgumentError, "Incomplete Deck" if all_cards.size != 52
        raise ArgumentError, "Card Discrepancy" if all_cards.uniq.length != all_cards.length
      end
    end

    def manager
      User.find(@state[:manager_id])
    end

    # Games older than a day are considered stale
    def is_stale?
      @state[:created_at].nil? ||
        (Time.now - Time.at(@state[:created_at])) > 86400
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

    def is_manager?(user_id)
      @state[:manager_id] == user_id
    end

    def is_common_phase?
      [:flop, :turn, :river].include? @deck.phase
    end

    def is_playing?(user_id)
      players.any?{ |p| p.user_id == user_id&.to_i }
    end

    def has_cards?(user_id)
      return false unless is_playing? user_id
      player_by_user_id(user_id).hole_cards.size > 0
    end

    def is_contested?
      players.count{ |p| p.hole_cards.size > 0 } > 1
    end

    def player_by_user_id(user_id)
      @players.find{ |p| p.user_id == user_id&.to_i }
    end

    def to_hash
      @state.merge(
        deck: deck.to_hash,
        players: @players.map(&:to_hash),
        button_index: @button_index
      )
    end

    def qr_code
      RQRCode::QRCode.new @state[:url] + "/#{@state[:id]}"
    end

    def advance
      Debug.this "Advancing game"
      if @players.size < 1
        raise ArgumentError, "Please add at least one player to deal"
      end
      if @button_index.nil?
        raise ArgumentError, "Determine the button first"
      end
      case @deck.phase
      when :deal
        deal
        @deck.advance
      when :river
        new_hand
      else
        @deck.advance
      end
      change_color
    end

    def new_hand
      reset
      move_button
      change_color
    end

    # set color for the next step, so folks can know
    # if their client is up to date
    def change_color
      @state = @state.merge(step_color: rand_color)
    end

    def reset
      @players.each{ |player| @deck.discard(player.reset) }
      @deck.reset
    end

    def move_button
      @button_index = (@button_index + 1) % @players.size
    end

    # def winner
    #   @players.max do |a,b|
    #     a.state[:hole_cards].sum(&:absolute_value) <=> b.
    #       state[:hole_cards].sum(&:absolute_value)
    #   end
    # end

    def add_player(player = Poker::Player.new({}))
      Debug.this "Adding player #{player.state[:name]}"
      raise ArgumentError, 'Game is full' if @players.size >= 10
      if @players.any?{|p| p.user_id == player.user_id }
        raise ArgumentError,
          "The User Name '#{player.state[:name]}' is taken."
      end
      @players << player
    end

    def remove_player(user_id)
      if (player = @players.
        find{|p| p.user_id == user_id&.to_i }
      )
        @players.delete(player)
      end
      player
    end

    def is_ready?
      @players.size > 0 && !@button_index.nil?
    end

    def players_in_turn_order
      return @players if @players.size < 2
      return @players if @button_index.nil?

      @players[(@button_index + 1)..-1] +
      @players[0..@button_index]
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

    def determine_button
      reset
      @deck.wash
      @players.each{|player| player.draw(@deck.draw) }
      winner = @players.max do |a,b|
        a.hole_cards.sum(&:absolute_value) <=> b.
          hole_cards.sum(&:absolute_value)
      end
      reset
      Debug.this "Winner: #{winner.state[:name]} \n" \
        "Button index: #{players.index(winner)}"
      @button_index = players.index(winner)
    end

    def deal
      2.times do
        players_in_turn_order.each do |player|
          player.draw(@deck.draw)
        end
      end
    end
  end
end
