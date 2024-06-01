# frozen_string_literal: true

require "litecable"
require "anycable"

# Sample chat application
module Chat
  class Connection < LiteCable::Connection::Base # :nodoc:
    identified_by :user, :sid

    def connect
      self.user = cookies["user"]
      self.sid = request.params["sid"]
      #reject_unauthorized_connection unless user
      $stdout.puts "#{user} connected"
    end

    def disconnect
      $stdout.puts "#{user} disconnected"
    end
  end

  class Channel < LiteCable::Channel::Base # :nodoc:
    identifier :game

    def subscribed
      reject unless game_id
      stream_from "game_#{game_id}"
    end

    def speak(data)
      LiteCable.broadcast "game_#{game_id}",
        {user: user, message: data["message"], sid: sid}
    end

    private

    def game_id
      params.fetch("game_id")
    end
  end
end
