module LandingPages
  def self.registered(app)
    # Route for the home landing page
    #
    app.get '/?' do
      slim :index
    end
  end
end
