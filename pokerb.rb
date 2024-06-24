#!/usr/bin/env ruby -I ../lib -I lib
# frozen_string_literal: true

require "sinatra/base"
require "sinatra/reloader"
require "sinatra/namespace"
require "sinatra/cookies"

require "slim"
require "yaml"
require "securerandom"
require "byebug"
require 'socket'

require "./poker"

IP_ADDRESS =
  Socket.
    ip_address_list.
    map{|addr| addr.inspect_sockaddr }.
    reject do |addr|
      addr.length > 15 ||
        addr == "127.0.0.1" ||
        addr.count(".") < 3
    end.
    first

class Flash
  attr_reader :is_read
  attr_accessor :message

  def initalize(is_read: false, message: "")
    @is_read = is_read
  end

  def read
    @is_read = true
    @message
  end
end

class PokeRb < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    also_reload Dir.pwd + '/lib/*.rb'
    also_reload Dir.pwd + '/lib/**/*.rb'
  end

  configure :production do
    set :bind, IP_ADDRESS
  end

  register Sinatra::Namespace
  helpers Sinatra::Cookies
  enable :sessions
  set :session_secret,
    "secret_key_with_size_of_32_bytes_dff054b19c2de43fc406f251376ad40"
  set :public_folder, "assets"

  def self.debug(msg)
    return unless !ENV["DEBUG"].nil?

    count = msg.length
    divider = []
    [msg.length, 79].min.times{ divider << "-" }
    puts divider.join
    puts "DEBUG: #{msg}"
    puts divider.join
  end

  # Returns the full path to the root folder for
  # the :game_id value given
  #
  #   Example: /Users/some_user/audio-images/games/2fgdaf"
  #
  def self.game_root(game_id)
    Dir.pwd + "/games/#{game_id}"
  end

  # Loads, reads and parses /games/:game_id/state.yml
  # for keeping track of game-specific metadata.
  #
  def self.load_state_for_game(game_id)
    YAML.load(
      File.open("#{PokeRb.game_root(game_id)}/state.yml")
    )
  end

  # Writes the game state to the system so we can resume
  # from errors and prevent having redundant requests.
  #
  def self.write_state(state)
    unless Dir.exist?(PokeRb.game_root(state[:id]))
      Dir.mkdir(PokeRb.game_root(state[:id]))
    end
    File.write(
      "#{PokeRb.game_root(state[:id])}/state.yml",
      state.to_yaml
    )
    state
  end

  def self.server_url(request)
    env = request.env
    parts = ["http://"]
    if !ENV["POKERB_HOSTNAME"].nil?
      parts << ENV["POKERB_HOSTNAME"]
    else
      parts << env["SERVER_NAME"]
    end
    parts << ":#{env["SERVER_PORT"]}" if env["SERVER_PORT"]
    parts.join
  end

  before do
    if session[:flash].nil? || session[:flash]&.is_read
      session[:flash] = Flash.new
    end
  end

  def set_game
    state = PokeRb.load_state_for_game(params["game_id"])
    @game = Poker::Game.new(state)
    join_path = "/games/#{@game.state[:id]}/join"
    unless session[:user]
      session[:flash].message =
        "You must be logged in to access this game."
      return redirect join_path
    end
    if @game.has_password?
      if @game.state[:password] != session["#{@game.state[:id]}_password"]
        session[:flash].message =
          "You must enter the correct password to access this game."
        return redirect join_path
      end
    end
  end

  get '/' do
    slim :index
  end

  get "/login" do
    slim :login
  end

  get "/logout" do
    session[:user] = nil
    cookies["user"] = nil
    redirect "/"
  end

  post "/login" do
    if params["user"]
      session[:user] = params["user"]
      cookies["user"] = params["user"]
      PokeRb.debug "User logged in: #{session[:user]}"
      redirect "/"
    else
      slim :login
    end
  end

  namespace '/games' do
    get '' do
      slim :games
    end

    post "/new" do
      PokeRb.debug "Creating new game"
      # TODO: check if game id is already taken
      @game = Poker::Game.new(
        manager: session[:user],
        password: params["password"],
        card_back: params["card_back"],
        url: PokeRb.server_url(request),
        is_fresh: true
      )
      @game.deck.reset
      @game.deck.wash
      @game.deck.shuffle
      PokeRb.write_state(@game.to_hash)

      # only set the password for the
      # manager's session if we set one
      if @game.has_password?
        PokeRb.debug "Setting password for manager"
        session["#{@game.state[:id]}_password"] =
          params["password"]
      end
      redirect "/games/#{@game.state[:id]}/community"
    end

    namespace '/:game_id' do
      get "" do
        set_game
        slim :game
      end

      get "/join" do
        state = PokeRb.load_state_for_game(params["game_id"])
        @game = Poker::Game.new(state)
        slim :join
      end

      post "/join" do
        state = PokeRb.load_state_for_game(params["game_id"])
        @game = Poker::Game.new(state)

        session[:user] = params["user"] if params["user"]

        @game.add_player Poker::Player.new(
          { name: session[:user] }
        )

        if @game.has_password?
          password_key = "#{@game.state[:id]}_password"
          session[password_key] = params["password"]
        end
        PokeRb.write_state(@game.to_hash)
        redirect "/games/#{@game.state[:id]}"
      rescue ArgumentError => e
        session[:flash].message = e.message
        return redirect "/games/#{params["game_id"]}/join"
      end

      get "/community" do
        set_game
        PokeRb.debug "Loading community cards for #{@game.state[:id]}"
        slim :community
      end

      #####################
      ## Manager Actions ##
      #####################
      post "/advance" do
        set_game
        if session[:user] == @game.state[:manager]
          @game.advance
          PokeRb.debug "Advanced to #{@game.deck.phase}"
          PokeRb.write_state(@game.to_hash)
        else
          session[:flash].message =
            "Only the manager can advance the game"
        end
        redirect "/games/#{@game.state[:id]}/community"
      rescue ArgumentError => e
        session[:flash].message = e.message
        return redirect "/games/#{params["game_id"]}/community"
      end

      post "/remove_player" do
        set_game
        if session[:user] != @game.state[:manager]
          session[:flash].message =
            "Only #{@game.state[:manager]} can remove players."
          redirect "/games/#{params["game_id"]}/community"
        end

        if (player = @game.player_by_name(params["player_name"]))
          if @game.has_cards?(player.name)
            @game.deck.discard(player.fold)
          end
          @game.remove_player(params["player_name"])
          PokeRb.write_state(@game.to_hash)
        end
        redirect "/games/#{params["game_id"]}/community"
      end

      ##################
      ## User Actions ##
      ##################
      post "/poll" do
        return unless (data = JSON.parse(request.body.read))

        state = PokeRb.load_state_for_game(data["game_id"])
        if data["step_color"] != state[:step_color]
          PokeRb.debug "Step color mismatch"
          return { in_sync: false }.to_json
        end
        { in_sync: true }.to_json
      end

      get "/fold" do
        set_game
        slim :fold
      end

      post "/fold" do
        set_game
        if (player = @game.player_by_name(session[:user]))
          break unless @game.has_cards?(player.name)
          @game.deck.discard(player.fold)
          PokeRb.write_state(@game.to_hash)
        end
        redirect "/games/#{@game.state[:id]}"
      end
    end
  end

  get '/assets/:asset_filename' do
    path = "#{Dir.pwd}/images/cards/#{params["asset_filename"]}"
    send_file path, :type => :png
  end
end
