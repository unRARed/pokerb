module System
  def self.registered(app)
    # Route for responding with system images
    #
    #   @param asset_filename [String] the filename of the image
    #   @return [File] the image file
    #
    app.get '/images/*image_path' do
      path = "#{Dir.pwd}/images/#{params["image_path"]}"
      send_file path, :type => :png
    end

    # Route for cleaning up stale games to free up
    # slug values and keep the database snappy
    #
    app.get "/cleanup/?" do
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
  end
end
