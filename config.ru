require 'bundler/setup'
Bundler.require(:default)
require './rbpkr'
require 'socket'

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

class RbPkr < Sinatra::Base
  configure :production do
    set :bind, IP_ADDRESS
  end
end

map "/" do
  run RbPkr
end
