require 'msgpack'

require 'packserv/client'
require 'packserv/exceptions'
require 'packserv/io_packer'
require 'packserv/io_unpacker'
require 'packserv/server'
require 'packserv/version'

module PackServ
  class << self
    def connect(host, port)
      Client.new(host, port).connect
    end

    def serve(port)
      Server.new(port).serve
    end
  end
end
