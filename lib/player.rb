module Poker
  class Player
    attr_accessor :state

    def initialize
      @state = {
        bankroll: 0
      }
    end

    def adjust_bankroll(amount)
      @state = @state.merge({
        bankroll: (@state[:bankroll] + amount)
      })
    end
  end
end
