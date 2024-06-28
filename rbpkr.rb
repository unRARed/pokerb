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
require "./debug"

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

class Notifier
  attr_reader :is_read
  attr_accessor :message, :color

  def initialize(is_read: false, message: "", color: "red")
    @is_read = is_read
    @color = color
  end

  def read
    @is_read = true
    @message
  end
end

class RbPkr < Sinatra::Base
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

  # Returns the full path to the root folder for
  # the :game_id value given
  #
  #   Example: /Users/some_user/rbpkr/games/2fgdaf"
  #
  def self.game_root(game_id)
    Dir.pwd + "/games/#{game_id}"
  end

  # Loads, reads and parses /games/:game_id/state.yml
  # for keeping track of game-specific metadata.
  #
  def self.load_state_for_game(game_id)
    YAML.load(
      File.open("#{RbPkr.game_root(game_id)}/state.yml")
    )
  end

  # Writes the game state to the system so we can resume
  # from errors and prevent having redundant requests.
  #
  def self.write_state(state)
    unless Dir.exist?(RbPkr.game_root(state[:id]))
      Dir.mkdir(RbPkr.game_root(state[:id]))
    end
    File.write(
      "#{RbPkr.game_root(state[:id])}/state.yml",
      state.to_yaml
    )
    state
  end

  def self.server_url(request)
    env = request.env
    parts = ENV["RACK_ENV"] == "production" ?
      ["https://"] : ["http://"]
    if !ENV["RBPKR_HOSTNAME"].nil?
      parts << ENV["RBPKR_HOSTNAME"]
    else
      parts << env["SERVER_NAME"]
    end
    unless ENV["RACK_ENV"] == "production"
      parts << ":#{env["SERVER_PORT"]}" if env["SERVER_PORT"]
    end
    parts.join
  end

  before do
    if session[:notice].nil? || session[:notice]&.is_read
      session[:notice] = Notifier.new
    end
  end

  def set_game
    state = RbPkr.load_state_for_game(params["game_id"])
    @game = Poker::Game.new(state)
    join_path = "/#{@game.state[:id]}/join"
    unless session[:user]
      session[:notice].message =
        "You must be logged in to access this game."
      return redirect join_path
    end
    if @game.has_password?
      if @game.state[:password] != session["#{@game.state[:id]}_password"]
        session[:notice].message =
          "You must enter the correct password to access this game."
        return redirect join_path
      end
    end
  end

  get '/assets/:asset_filename' do
    path = "#{Dir.pwd}/images/cards/#{params["asset_filename"]}"
    send_file path, :type => :png
  end

  get '/?' do
    slim :index
  end

  get "/login/?" do
    slim :login
  end

  get "/logout/?" do
    session[:user] = nil
    cookies["user"] = nil
    redirect "/"
  end

  post "/login/?" do
    if params["user"]
      session[:user] = params["user"]
      cookies["user"] = params["user"]
      Debug.this "User logged in: #{session[:user]}"
      redirect "/"
    else
      slim :login
    end
  end

  get '/new/?' do
    slim :new
  end

  post "/new/?" do
    Debug.this "Creating new game"
    # TODO: check if game id is already taken
    @game = Poker::Game.new(
      manager: session[:user],
      password: params["password"],
      card_back: params["card_back"],
      url: RbPkr.server_url(request),
      is_fresh: true
    )
    @game.deck.reset
    @game.deck.wash
    @game.deck.shuffle
    RbPkr.write_state(@game.to_hash)

    # only set the password for the
    # manager's session if we set one
    if @game.has_password?
      Debug.this "Setting password for manager"
      session["#{@game.state[:id]}_password"] =
        params["password"]
    end
    redirect "/#{@game.state[:id]}/community"
  end

  get "/cleanup/?" do
    begin
      # will have to do until we move to a real database
      raise ArgumentError, "Not authorized" unless request.
        env["HTTP_USER_AGENT"] == "Consul Health Check"
      (
        Dir.glob('./games/*').
          reject{|g| g.include? "lost+found" }
      ).each do |file|
        game_id = file.split('/').last
        Debug.this "Deleting #{game_id}"
        game = Poker::Game.new(RbPkr.load_state_for_game(game_id))
        if game.is_stale?
          Debug.this "Deleting #{game_id}"
          FileUtils.rm_rf(file)
        end
      end
    rescue ArgumentError => e
      e.message.include?("Not authorized") ?
        status(401) : status(400)
      return body('')
    end
    status 200
  end

  namespace '/:game_id' do
    get "/?" do
      set_game
      slim :game
    end

    get "/join/?" do
      state = RbPkr.load_state_for_game(params["game_id"])
      @game = Poker::Game.new(state)
      slim :join
    end

    post "/join/?" do
      state = RbPkr.load_state_for_game(params["game_id"])
      @game = Poker::Game.new(state)

      session[:user] = params["user"] if params["user"]

      @game.add_player Poker::Player.new(
        { name: session[:user] }
      )

      if @game.has_password?
        password_key = "#{@game.state[:id]}_password"
        session[password_key] = params["password"]
      end
      RbPkr.write_state(@game.to_hash)
      redirect "/#{@game.state[:id]}"
    rescue ArgumentError => e
      session[:notice].message = e.message
      return redirect "/#{params["game_id"]}/join"
    end

    get "/community/?" do
      set_game
      Debug.this "Loading community cards for #{@game.state[:id]}"
      slim :community
    end

    #####################
    ## Manager Actions ##
    #####################

    get "/determine_button/?" do
      set_game
      if session[:user] == @game.state[:manager]
        @game.determine_button
        RbPkr.write_state(@game.to_hash)
        session[:notice].color = "green"
        session[:notice].message = "Button has been assigned."
      else
        session[:notice].message =
          "Only the manager can determine the button"
      end
      redirect "/#{params["game_id"]}/community"
    end

    get "/new_hand/?" do
      set_game
      if session[:user] == @game.state[:manager]
        @game.new_hand
        RbPkr.write_state(@game.to_hash)
      else
        session[:notice].message =
          "Only the manager can advance the game"
      end
      redirect "/#{params["game_id"]}/community"
    end

    post "/advance/?" do
      set_game
      if session[:user] == @game.state[:manager]
        @game.advance
        Debug.this "Advanced to #{@game.deck.phase}"
        RbPkr.write_state(@game.to_hash)
      else
        session[:notice].message =
          "Only the manager can advance the game"
      end
      redirect "/#{@game.state[:id]}/community"
    rescue ArgumentError => e
      session[:notice].message = e.message
      return redirect "/#{params["game_id"]}/community"
    end

    post "/remove_player/?" do
      set_game
      if session[:user] != @game.state[:manager]
        session[:notice].message =
          "Only #{@game.state[:manager]} can remove players."
        redirect "/#{params["game_id"]}/community"
      end

      if (player = @game.player_by_name(params["player_name"]))
        if @game.has_cards?(player.name)
          @game.deck.discard(player.fold)
        end
        @game.remove_player(params["player_name"])
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{params["game_id"]}/community"
    end

    ##################
    ## User Actions ##
    ##################
    post "/poll/?" do
      return unless (data = JSON.parse(request.body.read))

      state = RbPkr.load_state_for_game(data["game_id"])
      if data["step_color"] != state[:step_color]
        Debug.this "Step color mismatch"
        return { in_sync: false }.to_json
      end
      { in_sync: true }.to_json
    end

    get "/fold/?" do
      set_game
      slim :fold
    end

    post "/fold/?" do
      set_game
      if (player = @game.player_by_name(session[:user]))
        break unless @game.has_cards?(player.name)
        @game.deck.discard(player.fold)
        @game.change_color
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{@game.state[:id]}"
    end
  end
end
