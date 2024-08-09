module Authentication
  def self.registered(app)
    app.get "/confirm/:token/?" do
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
      session[:notice].message =
        "Your account has been confirmed."
      session[:notice].color = "green"
      redirect "/set_name"
    rescue ActiveRecord::RecordInvalid => e
      session[:notice].message = e.message
      redirect "/"
    rescue ArgumentError => e
      session[:notice].message = e.message
      redirect "/"
    end

    # Route for logging in a user
    #
    app.get "/login/?" do
      slim :login
    end

    # Route for authenticating a user given the
    # contents of the login form
    #
    app.post "/login/?" do
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
      if (game = Game.find_by(id: current_user&.current_game_id))
        return redirect "/#{game.slug}"
      end
      redirect "/"
    rescue ArgumentError => e
      session[:notice].message = e.message
      slim :login
    rescue ActiveRecord::RecordInvalid => e
      session[:notice].message = e.message
      slim :login
    end

    # Route for logging out a user
    #
    app.get "/logout/?" do
      session[:user_id] = nil
      session[:game_id] = nil
      session[:notice].message = "You have been logged out."
      session[:notice].color = "green"
      redirect "/"
    end

  end
end
