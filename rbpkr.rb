#!/usr/bin/env ruby -I ../lib -I lib
# frozen_string_literal: true

require "sinatra/base"
require "sinatra/reloader"
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
require "./emailer"
require "./notifier"

require "./debug"

Dir.glob("./controllers/**/*.rb").each{|f| require f }

# List of path fragments that should be
# reachable without a user session
#
PUBLIC_ROUTES = [
  /\A\/\z/,
  /\A\/cleanup/,
  /\A\/signup/,
  /\A\/login/,
  /\A\/password/,
  /\A\/confirm/,
  /\A\/set_name/,
  /\A\/images\/.*\.png/,
  /\A\/[A-Z]{4}/,
]

class NotFoundError < StandardError; end

class RbPkr < Sinatra::Base
  configure :development do
    require "letter_opener"

    register Sinatra::Reloader
    also_reload Dir.pwd + '/lib/*.rb'
    also_reload Dir.pwd + '/lib/**/*.rb'
    also_reload Dir.pwd + '/controllers/**/*.rb'

    # TODO: Actually create the style guide
    #
    get '/style-guide/?' do
      slim :style_guide, layout: :layout
    end
  end

  configure :production do
    set :port, 8080
  end

  register Sinatra::Namespace
  enable :sessions
  set :session_secret,
    "secret_key_with_size_of_32_bytes_dff054b19c2de43fc406f251376ad40"

  register Sinatra::ActiveRecordExtension
  set :database_file, "config/database.yml"

  register System
  register LandingPages
  register Authentication
  register Users
  register Games

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
    state = RbPkr.load_state_for_game(@game_slug)
    Debug.this "Setting game #{@game_slug}: #{state}"
    @game = Poker::Game.new(state)

    if @game.has_password?
      if @game.password != session["#{@game.slug}_password"]
        session[:notice].message =
          "You must enter the correct password " \
            "to access this game."
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
      URI(
        "https://www.google.com/recaptcha/api/siteverify"),
        {
          response: token,
          secret: ENV["RBPKR_RECAPTCHA_SECRET"]
        }
      )&.body

    JSON.parse(recaptcha_result)&.dig("success") == true
  end

  # Helper method for ensuring userx are logged in
  # or that their current path is a public one
  #
  def require_session
    return if logged_in?

    unless PUBLIC_ROUTES.any?{ |r| request.path_info.match? r }
      Debug.this "#{request.path_info} is not public"
      session[:notice].message =
        "You must be signed in to do that."
      redirect "/login"
    end
  end

  before do
    # Akin to Rails Flash messages, for setting and
    # displaying simple notices in views
    #
    if session[:notice].nil? || session[:notice]&.is_read
      session[:notice] = Notifier.new
    end

    require_session

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
end
