require_relative 'player'
require_relative 'deck'
require_relative 'hand'
require 'securerandom'
require_relative '../debug'

module Poker
  class Game
    attr_reader :slug,
      :state,
      :deck,
      :players,
      :all_cards,
      :dealer,
      :password,
      :button_index,
      :manager

    def initialize(state = {})
      @state = {
        slug: SecureRandom.
          base64.gsub(/[^a-zA-Z]/, '')[0..3].upcase,
        user_id: nil,
        password: "",
        step_color: nil,
        players: [],
        deck_stack: [],
        deck_discarded: [],
        deck_community: [],
        deck_phase: :deal,
        card_back: "DefaultBack.png",
        button_index: nil
      }.merge(state)

      @step_color = @state[:step_color].nil? ?
        rand_color : @state[:step_color]
      @slug = @state[:slug]
      @deck = Poker::Deck.new(
        stack: @state[:deck_stack] || [],
        discarded: @state[:deck_discarded] || [],
        community: @state[:deck_community] || [],
        phase: @state[:deck_phase].to_sym,
      )
      @password = @state[:password]
      @players = @state[:players].map{ |p| Poker::Player.new p.symbolize_keys }
      @button_index = @state[:button_index]

      Debug.this "Game #{@slug} initialized"
      Debug.this "Players: #{players.map(&:state).map{ |p| p[:name] }}"
    end

    def manager
      User.find(@state[:user_id])
    end

    def phase
      @deck.phase
    end

    # Games which haven't been updated in 24 hours are stale
    #
    def is_stale?
        (Time.now - Time.at(@state[:updated_at])) > 86400
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

    def is_manager?(target_id)
      @state[:user_id] == target_id
    end

    def menu
      items = []
      items << {
        path: "/#{@slug}/determine_button",
        text: "Draw for the Button",
        is_primary: true
      } if @players.size > 0 && @button_index.nil?
      items << {
        path: "/#{@slug}/determine_button",
        text: "Re-Draw the Button",
        is_primary: false
      } if @players.size > 0 && !@button_index.nil?
      items << {
        path: "/#{@slug}/new_hand",
        text: "Start new hand",
        is_primary: true
      } if is_ready? && !is_contested?
      items
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
      {
        slug: @slug,
        user_id: @state[:user_id],
        password: @state[:password],
        card_back: @state[:card_back],
        # things that change after creation
        step_color: @step_color,
        button_index: @button_index,
        players: @players.map(&:to_hash)
      }.merge(deck.to_hash)
    end

    def qr_code_size
      case menu.size
      when 2
        4
      when 3
        5
      else
        3
      end
    end

    def advance
      Debug.this "Advancing game"
      if @players.size < 1
        raise ArgumentError, "Please add at least one player to deal"
      end
      if @button_index.nil?
        raise ArgumentError, "Draw for the button first"
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
      @step_color = rand_color
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
      change_color
      Debug.this "Winner: #{winner.name} \n" \
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
