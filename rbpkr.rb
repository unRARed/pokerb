#!/usr/bin/env ruby -I ../lib -I lib
# frozen_string_literal: true

require "sinatra/base"
require "sinatra/reloader"
require "sinatra/namespace"
require "sinatra/activerecord"


require 'uri'
require 'net/http'
require "slim"
require "securerandom"
require "byebug"
require 'socket'
require 'rqrcode'
require 'mail'

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

class NotFoundError < StandardError; end

# A simple class for storing and displaying
# simple notifications in the UI
#
class Notifier
  attr_reader :is_read
  attr_accessor :message, :color

  def initialize(is_read: false, message: "", color: "orange")
    @is_read = is_read
    @color = color
  end

  def read
    @is_read = true
    @message
  end
end

class Emailer
  CONFIG = {
    address: ENV['RBPKR_SMTP_HOST'],
    port: 587,
    domain: ENV['RBPKR_SMTP_DOMAIN'],
    user_name: ENV['RBPKR_SMTP_USERNAME'],
    password: ENV['RBPKR_SMTP_PASSWORD'],
    authentication: 'plain',
    enable_starttls_auto: true
  }

  def initialize(env = :development)
    Mail.defaults do
      case env
      when :development
        delivery_method(
          LetterOpener::DeliveryMethod,
          location: Dir.pwd + '/tmp/letter_opener'
        )
      when :test
        delivery_method(:test)
      else
        delivery_method(:smtp, CONFIG)
      end
    end
  end

  def send_activation_email(user)
    # User.save is supposed to trigger setting the
    # token, but doesn't seem to with Sinatra
    user.regenerate_email_confirmation_token
    email = Mail.new do
      part :content_type => "multipart/mixed" do |p1|
        p1.part :content_type => "multipart/related" do |p2|
          p2.part :content_type => "multipart/alternative",
            :content_disposition => "inline" do |p3|
            p3.part :content_type => "text/plain; charset=utf-8",
              :body => "Before using RbPkr, you " \
                "need to confirm your email address. Follow " \
                "this URL to activate your account: " \
                "#{RbPkr.server_url}/confirm" \
                "/#{user.email_confirmation_token}"
            p3.part :content_type => "text/html; charset=utf-8",
              :body => Tilt.new("views/email_confirmation.slim").
                render(self, url: "#{RbPkr.server_url}/confirm/" \
                  "#{user.email_confirmation_token}"
                )
          end
        end
      end
      from 'RbPkr <noreply@rbpkr.com>'
      to user.email
      subject 'Confirm your account at RbPkr.com'
    end
    email.deliver
  end
end

class RbPkr < Sinatra::Base
  configure :development do
    require "letter_opener"

    register Sinatra::Reloader
    also_reload Dir.pwd + '/lib/*.rb'
    also_reload Dir.pwd + '/lib/**/*.rb'

    get '/style-guide/?' do
      slim :style_guide, layout: :layout
    end
  end

  configure :production do
    set :bind, IP_ADDRESS
  end

  register Sinatra::Namespace
  enable :sessions
  set :session_secret,
    "secret_key_with_size_of_32_bytes_dff054b19c2de43fc406f251376ad40"

  set :game_slug, capture: { slug: /[A-Z]{4}/ }

  register Sinatra::ActiveRecordExtension
  # set :database, {adapter: "sqlite3", database: "games/foo.sqlite3"}

  def self.mailer_config
    {
      address: ENV['RBPKR_SMTP_HOST'],
      port: 587,
      domain: ENV['RBPKR_SMTP_DOMAIN'],
      user_name: ENV['RBPKR_SMTP_USERNAME'],
      password: ENV['RBPKR_SMTP_PASSWORD'],
      authentication: 'plain',
      enable_starttls_auto: true
    }
  end

  # Returns hash of the game state for the given :game_slug
  #
  #   @param game_slug [String] the game slug identifier
  #   @return [Hash] the game state
  #
  def self.load_state_for_game(game_slug)
    if (game = Game.find_by(slug: game_slug))
      return game.attributes.symbolize_keys
    end
    Debug.this "Could not find game: #{game_slug}"
    raise NotFoundError, "Could not find game: #{game_slug}"
  end

  # Finds or initializes a game model instance
  # and writes the given state to the database
  #
  #  @param state [Hash] the game state
  #  @return [Hash] the new game state from the database
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

  # Returns the server URL for creating dynamic URLs
  #
  #   @param req [Sinatra::Request] the request object
  #   @return [String] the base url for the server
  #
  def self.server_url(req = nil)
    env = req&.env
    parts = RbPkr.production? ?  ["https://"] : ["http://"]
    parts <<
      if env && !env["SERVER_NAME"].nil?
        env["SERVER_NAME"]
      elsif !ENV["RBPKR_HOSTNAME"].nil?
        ENV["RBPKR_HOSTNAME"]
      else
        "localhost"
      end
    if env && !env["SERVER_PORT"].nil?
      parts << ":#{env["SERVER_PORT"]}"
    end
    parts.join
  end

  # Returns a QR code for the given game slug
  #
  #   @param game_slug [String] the game slug identifier
  #   @return [RQRCode::QRCode] the QR code object
  #
  def self.qr_code(game_slug)
    RQRCode::QRCode.new "#{RbPkr.server_url}/#{game_slug}"
  end

  def self.is_safe_path?(path_info)
    path_info == "/" || ["/images", "/logout", "/confirm"].
      any?{ |p| path_info.start_with? p }
  end

  # A helper method for getting the game instance and
  # marrying the game state to the Poker::Game object.
  # Sets the @game instance variable.
  #
  #  @return [Poker::Game] the game instance
  #
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

  # Helper method for getting the current user
  #
  #  @return [User] the logged in user
  #
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  # Helper method for checking if a user is logged in
  #
  #   @return [Boolean] whether the user is logged in
  #
  def logged_in?; !current_user.nil? end

  def passed_recaptcha?(token)
    return true if ["test"].include? ENV["RACK_ENV"]

    recaptcha_token = params["g-recaptcha-response"]
    recaptcha_result = Net::HTTP.post_form(
      URI("https://www.google.com/recaptcha/api/siteverify"), {
        response: token, secret: ENV["RBPKR_RECAPTCHA_SECRET"]
      }
    )&.body

    JSON.parse(recaptcha_result)&.dig("success") == true
  end

  before do
    # Akin to Rails Flash messages, for setting and
    # displaying simple notices in views
    #
    if session[:notice].nil? || session[:notice]&.is_read
      session[:notice] = Notifier.new
    end

    # User has signed up, but they haven't confirmed their email
    if (
      !RbPkr.is_safe_path?(request.path_info) &&
      logged_in? && !current_user.is_confirmed?
    )
      session[:notice].message = "Please check your email " \
        "#{current_user.email} and confirm your RbPkr account " \
        "to get in the game."
      session[:notice].color = "green"
      return redirect "/"
    end

    # User is confirmed, but they haven't set their name yet
    if (
      !RbPkr.is_safe_path?(request.path_info) &&
      request.path_info != "/set_name" &&
      logged_in? && current_user.name.nil?
    )
      return redirect "/set_name"
    end
  end

  # Route for responding with system images
  #
  #   @param asset_filename [String] the filename of the image
  #   @return [File] the image file
  #
  get '/images/*image_path' do
    path = "#{Dir.pwd}/images/#{params["image_path"]}"
    send_file path, :type => :png
  end

  # Route for the home landing page
  #
  get '/?' do
    slim :index
  end

  # Route for signing up a new user
  #
  get "/signup/?" do
    @user = User.new
    slim :signup
  end

  # Route for creating a new user per the contents
  # submitted in the signup form
  #
  post "/signup/?" do
    raise ArgumentError, "What are you doing?" unless params["user"]

    unless passed_recaptcha?(params["g-recaptcha-response"])
      raise ArgumentError, "What are you doing?"
    end

    @user = User.new(
      email: params["user"]["email"],
      password: params["user"]["password"],
      created_at: Time.now,
      updated_at: Time.now,
    )
    @user.save!

    Emailer.new(settings.environment).send_activation_email(@user)

    session[:user_id] = @user.id
    session[:notice].message = "An email has been sent to " \
      "#{@user.email}. Please confirm your account to play."
    Debug.this "New user ID ##{current_user.id} signed up"
    redirect "/"
  rescue ActiveRecord::RecordInvalid => e
    session[:notice].message = e.message
    slim :signup
  rescue ArgumentError => e
    session[:notice].message = e.message
    slim :signup
  end

  get "/confirm/:token/?" do
    unless (@user =
      User.find_by(email_confirmation_token: params[:token])
    )
      raise(
        ArgumentError,
        "Something went wrong confirming your account."
      )
    end

    # Update around validations to prevent name
    # validation from firing prematurely
    @user.update_columns(
      email_confirmation_token: nil,
      email_confirmed_at: Time.now,
      updated_at: Time.now,
    )
    session[:user_id] = @user.id
    session[:notice].message = "Your account has been confirmed."
    redirect "/set_name"
  rescue ActiveRecord::RecordInvalid => e
    session[:notice].message = e.message
    redirect "/"
  rescue ArgumentError => e
    session[:notice].message = e.message
    redirect "/"
  end

  get "/set_name/?" do
    return redirect "/" if logged_in? && !current_user.name.nil?

    slim :set_name
  end

  post "/set_name/?" do
    current_user.update!(
      name: params["user"]["name"],
      updated_at: Time.now,
    )
    Debug.this "User ID ##{current_user.id} " \
      "set name to: #{current_user.name}"
    session[:notice].message = "Welcome, #{current_user.name}"
    session[:notice].color = "green"
    redirect "/"
  rescue ActiveRecord::RecordInvalid => e
    session[:notice].message = e.message
    slim :set_name
  rescue ArgumentError => e
    session[:notice].message = e.message
    slim :set_name
  end


  # Route for logging in a user
  #
  get "/login/?" do
    slim :login
  end

  # Route for logging out a user
  #
  get "/logout/?" do
    session[:user_id] = nil
    session[:notice].message = "You have been logged out."
    session[:notice].color = "green"
    redirect "/"
  end

  # Route for authenticating a user given the
  # contents of the login form
  #
  post "/login/?" do
    unless passed_recaptcha?(params["g-recaptcha-response"])
      raise ArgumentError, "What are you doing?"
    end

    @user = User.find_by(email: params["user"]["email"])
    raise ArgumentError, "Try again" unless @user
    raise ArgumentError, "Try again" unless
      @user.authenticate(params["user"]["password"])

    @user.validate!

    session[:user_id] = @user.id
    session[:notice].message = "Welcome back, #{@user[:name]}"
    session[:notice].color = "green"
    Debug.this "User logged in: #{current_user.name}"
    redirect "/"
  rescue ArgumentError => e
    session[:notice].message = e.message
    slim :login
  rescue ActiveRecord::RecordInvalid => e
    session[:notice].message = e.message
    slim :login
  end

  # Route for customizing a potential game
  #
  get '/new/?' do
    slim :new
  end

  # Route for creating a new game based on the
  # contents of the new game form
  #
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
      session["#{@game.slug}_password"] = @game.password.downcase
    end
    redirect "/#{@game.slug}/community"
  end

  # Route for cleaning up stale games to free up
  # slug values and keep the database snappy
  #
  get "/cleanup/?" do
    begin
      # will have to do until we move to a real database
      raise ArgumentError, "Not authorized" unless request.
        env["HTTP_USER_AGENT"] == "Consul Health Check"
      Game.all.each do |game|
        if Poker::Game.new(game.attributes.symbolize_keys).is_stale?
          Debug.this "Destroying stale game: #{game.slug}"
          game.destroy
        end
      end
    rescue ArgumentError => e
      e.message.include?("Not authorized") ?
        status(401) : status(400)
      return body('')
    end
    status 200
  end

  ####################
  ## Game Namespace ##
  ####################

  # Namespace for game-specific routes. For some reason, this
  # overrides all the root routes even with them defined above.
  # As a workaround, we match on the game slug pattern.
  namespace '/:game_slug' do
    before do
      pass unless params["game_slug"].match? /[A-Z]{4}/
      state = RbPkr.load_state_for_game(params["game_slug"])
    rescue NotFoundError => e
      session[:notice].message = e.message
      redirect "/"
    end
    # Route for displaying the hole cards for the
    # logged in user for the current game
    #
    get "/?" do
      RbPkr.load_state_for_game(params["game_slug"])
      set_game
      slim :game
    rescue NotFoundError, ArgumentError => e
      session[:notice].message = e.message
      redirect "/"
    end

    # Route for joining a new user to the game
    #
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

    # Route for prompting the user for a password
    # when the game is password-protected
    #
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
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for authenticating the game password
    #
    post "/password/?" do
      state = RbPkr.load_state_for_game(params["game_slug"])
      @game = Poker::Game.new(state)
      unless params["password"].present?
        raise ArgumentError, "No password provided"
      end
      unless @game.password.downcase == params["password"].downcase
        raise ArgumentError, "Password incorrect"
      end
      session["#{@game.slug}_password"] = params["password"].downcase
      session[:notice].message = "Password accepted"
      session[:notice].color = "green"
      redirect "/#{@game.slug}"
    rescue ArgumentError => e
      session[:notice].message = e
      redirect "/#{params["game_slug"]}/password"
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for displaying the shared view of community cards
    #
    get "/community/?" do
      set_game
      Debug.this "Loading community cards for #{@game.slug}"
      slim :community
    rescue ArgumentError => e
      session[:notice].message = e
      redirect "/#{params["game_slug"]}"
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    #####################
    ## Manager Actions ##
    #####################

    # Route for determining who is the dealer
    #
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
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for immediately advancing the game to the next
    # deal phase without seeing the remaining streets
    #
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
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for advancing the game to the next phase
    # of the deck, e.g. from pre-flop to flop
    #
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
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for removing a player from the game
    #
    post "/remove_player/?" do
      set_game
      if current_user.id != @game.state[:user_id]
        session[:notice].message =
          "Only #{@game.manager.name} can remove players."
        redirect "/#{params["game_slug"]}/community"
      end

      if (player = @game.player_by_user_id(params["player_user_id"]))
        if @game.is_player_in_hand?(player.user_id)
          @game.deck.discard(player.fold)
        end
        @game.remove_player(params["player_user_id"])
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{params["game_slug"]}/community"
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    ##################
    ## User Actions ##
    ##################

    # Route for periodically checking the current game
    # state for synchronization
    #
    post "/poll/?" do
      return unless (data = JSON.parse(request.body.read))

      state = RbPkr.load_state_for_game(data["game_slug"])
      if data["step_color"] != state[:step_color]
        Debug.this "Step color mismatch"
        return { in_sync: false }.to_json
      end
      { in_sync: true }.to_json
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for confirming the user's intention to fold
    #
    get "/fold/?" do
      set_game
      slim :fold
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end

    # Route for emptying the user's hole cards
    #
    post "/fold/?" do
      set_game
      if (player = @game.player_by_user_id(current_user.id))
        break unless @game.is_player_in_hand?(player.user_id)
        @game.deck.discard(player.fold)
        @game.change_color
        RbPkr.write_state(@game.to_hash)
      end
      redirect "/#{@game.slug}"
    rescue NotFoundError => e
      session[:notice].message = e
      redirect "/"
    end
  end
end
