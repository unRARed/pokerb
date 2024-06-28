#!/usr/bin/env ruby -I ../lib -I lib
# frozen_string_literal: true

class Debug
  def initialize(msg)
    count = msg.length
    divider = []
    [msg.length + 7, 79].min.
      times{ divider << ["♠", "♣", "♥", "♦"].sample }
    puts divider.join
    puts "DEBUG: #{msg}"
    puts divider.join
  end

  def self.this(msg)
    return unless !ENV["DEBUG"].nil?
    new(msg)
  end
end
