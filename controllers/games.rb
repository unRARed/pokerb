require "sinatra/base"
require "sinatra/namespace"

module Games
  def self.registered(app)
    # Route for customizing a potential game
    #
    app.get '/new/?' do
      slim :new
    end

    # Route for creating a new game based on the
    # contents of the new game form
    #
    app.post "/new/?" do
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
        session["#{@game.slug}_password"] =
          @game.password.downcase
      end
      redirect "/#{@game.slug}/community"
    end

    ####################
    ## Game Namespace ##
    ####################

    # Namespace for game-specific routes. Regex matches
    # four uppercase letters for the game->slug
    #
    app.namespace /\/([A-Z]{4})/i do
      before do
        @game_slug = params["captures"].first
        state = RbPkr.load_state_for_game(@game_slug)
      rescue NotFoundError => e
        session[:notice].message = e.message
        redirect "/"
      end

      # Route for displaying the hole cards for the
      # logged in user for the current game
      #
      get "/?" do
        RbPkr.load_state_for_game(@game_slug)
        set_game
        slim :game
      rescue NotFoundError, ArgumentError => e
        session[:notice].message = e.message
        redirect "/"
      end

      # Route for joining a new user to the game
      #
      get "/join/?" do
        unless logged_in?
          if (game = Game.find_by(slug: @game_slug))
            session[:game_id] = game.id
          end
          session[:notice].color = "green"
          session[:notice].message =
            "You must be signed in to do that."
          return redirect "/login"
        end
        state = RbPkr.load_state_for_game(@game_slug)
        @game = Poker::Game.new(state)

        if @game.player_by_user_id(current_user.id)
          raise ArgumentError, "You're already in this game"
        end

        @game.add_player Poker::Player.new(
          { user_id: current_user.id }
        )
        if (game = Game.find_by(slug: @game_slug))
          current_user.update!(current_game_id: game.id)
        end

        RbPkr.write_state(@game.to_hash)
        session[:notice].color = "green"
        session[:notice].message = "You have joined the game."
        redirect "/#{@game_slug}"
      rescue ArgumentError => e
        session[:notice].message = e.message
        redirect "/#{@game_slug}"
      end

      # Route for prompting the user for a password
      # when the game is password-protected
      #
      get "/password/?" do
        state = RbPkr.load_state_for_game(@game_slug)
        @game = Poker::Game.new(state)
        unless @game.has_password?
          raise ArgumentError,
            "This is not a password-protected game."
        end
        if @game.password == session["#{@game.slug}_password"]
          raise ArgumentError, "You're already in this game."
        end
        slim :password
      rescue ArgumentError => e
        session[:notice].message = e
        redirect "/#{@game_slug}"
      rescue NotFoundError => e
        session[:notice].message = e
        redirect "/"
      end

      # Route for authenticating the game password
      #
      post "/password/?" do
        state = RbPkr.load_state_for_game(@game_slug)
        @game = Poker::Game.new(state)
        unless params["password"].present?
          raise ArgumentError, "No password provided"
        end
        unless (
          @game.password.downcase == params["password"].downcase
        )
          raise ArgumentError, "Password incorrect"
        end
        session["#{@game.slug}_password"] =
          params["password"].downcase
        session[:notice].message = "Password accepted"
        session[:notice].color = "green"
        redirect "/#{@game.slug}"
      rescue ArgumentError => e
        session[:notice].message = e
        redirect "/#{@game_slug}/password"
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
        redirect "/#{@game_slug}"
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
        redirect "/#{@game_slug}/community"
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
        redirect "/#{@game_slug}/community"
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
        return redirect "/#{@game_slug}/community"
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
          redirect "/#{@game_slug}/community"
        end

        if (player = @game.
          player_by_user_id(params["player_user_id"])
        )
          if @game.is_player_in_hand?(player.user_id)
            @game.deck.discard(player.fold)
          end
          @game.remove_player(params["player_user_id"])
          RbPkr.write_state(@game.to_hash)
        end
        session[:notice].color = "green"
        session[:notice].message = "Player removed."
        redirect "/#{@game_slug}/community"
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

        state = RbPkr.load_state_for_game(data["@game_slug"])
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
end
