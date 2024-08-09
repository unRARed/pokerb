module Users
  def self.registered(app)
    # Route for prompting a new user to sign up with
    # an email and password pair
    #
    app.get "/signup/?" do
      @user = User.new
      slim :signup
    end

    # Route for creating a new user per the contents
    # submitted in the signup form
    #
    app.post "/signup/?" do
      unless params["user"]
        raise ArgumentError, "What are you doing?"
      end

      unless passed_recaptcha?(params["g-recaptcha-response"])
        raise ArgumentError, "What are you doing?"
      end

      @user = User.new(
        email: params["user"]["email"],
        password: params["user"]["password"],
        created_at: Time.now,
        updated_at: Time.now,
        # for getting the user into the game
        # they either signed up from or last joined
        current_game_id: session[:game_id]
      )
      @user.save!

      Emailer.new(settings.environment).
        send_activation_email(@user)

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

    # Route for prompting user to set
    # a public display name
    #
    app.get "/set_name/?" do
      return redirect "/" if logged_in? && !current_user.name.nil?

      slim :set_name
    end

    # Route for setting the user's public
    # display name (after confirming email)
    #
    app.post "/set_name/?" do
      current_user.update!(
        name: params["user"]["name"],
        updated_at: Time.now,
      )
      Debug.this "User ID ##{current_user.id} " \
        "set name to: #{current_user.name}"
      session[:notice].message = "Welcome, #{current_user.name}"
      session[:notice].color = "green"
      if (game = Game.find_by(id: current_user&.current_game_id))
        return redirect "/#{game.slug}"
      end
      redirect "/"
    rescue ActiveRecord::RecordInvalid => e
      session[:notice].message = e.message
      slim :set_name
    rescue ArgumentError => e
      session[:notice].message = e.message
      slim :set_name
    end
  end
end
