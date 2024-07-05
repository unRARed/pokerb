#!/usr/bin/env ruby -I ../lib -I lib
# frozen_string_literal: true

require "sinatra/base"
require "sinatra/reloader"
require "sinatra/namespace"
require "sinatra/cookies"
require "sinatra/activerecord"

require "slim"
require "securerandom"
require "byebug"
require 'socket'
require 'rqrcode'

require "./models/user"
require "./models/game"
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

  register Sinatra::ActiveRecordExtension
  # set :database, {adapter: "sqlite3", database: "games/foo.sqlite3"}

  # Returns the full path to the root folder for
  # the :game_slug value given
  #
  #   Example: /Users/some_user/rbpkr/games/2fgdaf"
  #
  def self.game_root(game_slug)
    Dir.pwd + "/games/#{game_slug}"
  end

  # Loads, reads and parses /games/:game_slug/state.yml
  # for keeping track of game-specific metadata.
  #
  def self.load_state_for_game(game_slug)
    if (game = Game.find_by(slug: game_slug))
      return game.attributes.symbolize_keys
    end
    Debug.this "Could not find game: #{game_slug}"
    Game.new.attributes.symbolize_keys
  end

  # Writes the game state to the system so we can resume
  # from errors and prevent having redundant requests.
  #
  def self.write_state(state)
    Debug.this "Writing state: #{state}"
    if (game = Game.find_by(slug: state[:slug]))
      game.update!(state)
    else
      game = Game.new(state)
      game.save!
    end
    Debug.this state
    game.attributes.symbolize_keys
  end

  def self.server_url(req)
    env = req.env
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

  def self.qr_code(game_slug)
    RQRCode::QRCode.new "#{RbPkr.server_url}/#{game_slug}"
  end

  before do
    if session[:notice].nil? || session[:notice]&.is_read
      session[:notice] = Notifier.new
    end
  end

  def set_game
    state = RbPkr.load_state_for_game(params["game_slug"])
    Debug.this "Setting game #{params["game_slug"]}: #{state}"
    @game = Poker::Game.new(state)
    unless logged_in?
      session[:notice].message =
        "You must be logged in to access this game."
      return redirect "/login"
    end
    if @game.has_password?
      if @game.password != session["#{@game.slug}_password"]
        session[:notice].message =
          "You must enter the correct password to access this game."
        return redirect "/#{@game.slug}/password"
      end
    end
  end

  def current_user
    return nil unless !session["user_id"].nil?

    if (user = User.find(session["user_id"]))
      return user
    end
    nil
  end

  def logged_in?
    !current_user.nil? && current_user != ""
  end

  get '/assets/:asset_filename' do
    path = "#{Dir.pwd}/images/cards/#{params["asset_filename"]}"
    send_file path, :type => :png
  end

  get '/?' do
    slim :index
  end

  get "/signup/?" do
    @user = User.new
    slim :signup
  end

  post "/signup/?" do
    raise ArgumentError, "What are you doing?" unless params["user"]

    @user = User.create!(
      name: params["user"]["name"],
      password: params["user"]["password"],
      email: params["user"]["email"],
      created_at: Time.now,
      updated_at: Time.now,
    )
    # "Validation failed: Password can't be blank"
    #   without reloading...
    @user.reload

    session[:user_id] = @user.id
    cookies["user_id"] = @user.id
    session[:notice].message = "Welcome, #{@user[:name]}"
    session[:notice].color = "green"
    Debug.this "User logged in: #{current_user.name}"
    redirect "/"
  rescue ArgumentError => e
    session[:notice].message = e.message
    slim :login
  end

  get "/login/?" do
    slim :login
  end

  get "/logout/?" do
    session[:user_id] = nil
    cookies[:user_id] = nil
    session[:notice].message = "You have been logged out."
    session[:notice].color = "green"
    redirect "/"
  end

  post "/login/?" do
    @user = User.find_by(email: params["user"]["email"])
    raise ArgumentError, "Try again" unless @user
    raise ArgumentError, "Try again" unless
      @user.authenticate(params["user"]["password"])

    @user.validate!

    session[:user_id] = @user.id
    cookies["user_id"] = @user.id
    session[:notice].message = "Welcome back, #{@user[:name]}"
    session[:notice].color = "green"
    Debug.this "User logged in: #{current_user.name}"
    redirect "/"
  rescue ArgumentError => e
    session[:notice].message = e.message
    slim :login
  end

  get '/new/?' do
    slim :new
  end

  post "/new/?" do
    Debug.this "Creating new game"
    # TODO: check if game id is already taken
    @game = Poker::Game.new(
      {
        user_id: current_user.id,
        password: params["password"],
        card_back: params["card_back"]
      }.merge(
        Poker::Deck.new(
          stack: Poker::Deck.fresh.map{ |c| c.tuple }
        ).to_hash,
      )
    )
    @game.deck.reset
    @game.deck.wash
    @game.deck.shuffle

    RbPkr.write_state(@game.to_hash)

    # only set the password for the
    # manager's session if we set one
    if @game.has_password?
      Debug.this "Setting password for manager"
      session["#{@game.slug}_password"] = params["password"]
    end
    redirect "/#{@game.slug}/community"
  end

  get "/cleanup/?" do
    begin
      # will have to do until we move to a real database
      raise ArgumentError, "Not authorized" unless request.
        env["HTTP_USER_AGENT"] == "Consul Health Check"
      (
        Dir.glob('./games/*').
          reject{|g| g.include? "lost+found" }.
          reject{|g| g.include? "sqlite3" }
      ).each do |file|
        game_slug = file.split('/').last
        Debug.this "Deleting #{game_slug}"
        game = Poker::Game.new(RbPkr.load_state_for_game(game_slug))
        if game.is_stale?
          Debug.this "Deleting #{game_slug}"
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

  namespace '/:game_slug' do
    get "/?" do
      set_game
      slim :game
    end

    get "/join/?" do
      state = RbPkr.load_state_for_game(params["game_slug"])
      @game = Poker::Game.new(state)

      if @game.player_by_user_id(current_user.id)
        raise ArgumentError, "You're already in this game"
      end

      @game.add_player Poker::Player.new(
        { user_id: current_user.id }
      )

      RbPkr.write_state(@game.to_hash)
    rescue ArgumentError => e
      session[:notice].message = e.message
    ensure
      redirect "/#{params["game_slug"]}"
    end

    get "/password/?" do
      state = RbPkr.load_state_for_game(params["game_slug"])
      @game = Poker::Game.new(state)
      unless @game.has_password?
        raise ArgumentError, "This is not a password-protected game."
      end
      if @game.password == session["#{@game.slug}_password"]
        raise ArgumentError, "You're already in this game."
      end
      slim :password
    rescue ArgumentError => e
      session[:notice].message = e
      redirect "/#{params["game_slug"]}"
    end

    post "/password/?" do
      state = RbPkr.load_state_for_game(params["game_slug"])
      @game = Poker::Game.new(state)
      unless @game.password == params["password"]
        raise ArgumentError, "Password incorrect"
      end
      session["#{@game.slug}_password"] = params["password"]
      session[:notice].message = "Password accepted"
      session[:notice].color = "green"
      redirect "/#{@game.slug}"
    rescue ArgumentError => e
      session[:notice].message = e
      redirect "/#{params["game_slug"]}/password"
    end

    get "/community/?" do
      set_game
      Debug.this "Loading community cards for #{@game.slug}"
      slim :community
    end

    #####################
    ## Manager Actions ##
    #####################

    get "/determine_button/?" do
      set_game
      if current_user.id == @game.state[:user_id]
        @game.determine_button
        RbPkr.write_state(@game.to_hash)
        session[:notice].color = "green"
        session[:notice].message = "Button has been assigned."
      else
        session[:notice].message =
          "Only the manager can determine the button"
      end
      redirect "/#{params["game_slug"]}/community"
    end

    get "/new_hand/?" do
      set_game
      if current_user.id == @game.state[:user_id]
        @game.new_hand
        RbPkr.write_state(@game.to_hash)
      else
        session[:notice].message =
          "Only the manager can advance the game"
      end
      redirect "/#{params["game_slug"]}/community"
    end

    post "/advance/?" do
      set_game
      if current_user.id == @game.state[:user_id]
        @game.advance
        Debug.this "Advanced to #{@game.deck.phase}"
        RbPkr.write_state(@game.to_hash)
      else
        session[:notice].message =
          "Only the manager can advance the game"
      end
      redirect "/#{@game.slug}/community"
    rescue ArgumentError => e
      session[:notice].message = e.message
      return redirect "/#{params["game_slug"]}/community"
    end

    post "/remove_player/?" do
      set_game
      if current_user.id != @game.state[:user_id]
        session[:notice].message =
          "Only #{@game.manager.name} can remove players."
        redirect "/#{params["game_slug"]}/community"
      end

      if (player = @game.player_by_user_id(params["player_user_id"]))
        if @game.has_cards?(player.user_id)
          @game.deck.discard(player.fold)
        end
        @game.remove_player(params["player_user_id"])
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{params["game_slug"]}/community"
    end

    ##################
    ## User Actions ##
    ##################
    post "/poll/?" do
      return unless (data = JSON.parse(request.body.read))

      state = RbPkr.load_state_for_game(data["game_slug"])
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
      if (player = @game.player_by_user_id(current_user.id))
        break unless @game.has_cards?(player.user_id)
        @game.deck.discard(player.fold)
        @game.change_color
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{@game.slug}"
    end
  end
end
