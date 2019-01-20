require 'concurrent-ruby'
require 'socket'
require 'msgpack'

require 'packserv/client'
require 'packserv/default_protocol'
require 'packserv/exceptions'
require 'packserv/io_packer'
require 'packserv/io_unpacker'
require 'packserv/promised_thread'
require 'packserv/server'
require 'packserv/version'

module PackServ
  class << self
    def connect(host, port)
      Client.new.connect(host, port)
    end

    def serve(port)
      Server.new.serve(port)
    end
  end
end
