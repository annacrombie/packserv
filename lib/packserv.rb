require 'concurrent/executor/fixed_thread_pool'
require 'concurrent/executor/timer_set'
require 'concurrent/promises'

require 'forwardable'
require 'socket'
require 'msgpack'

require 'packserv/client'
require 'packserv/default_protocol'
require 'packserv/exceptions'
require 'packserv/io_packer'
require 'packserv/io_unpacker'
require 'packserv/msgpack_ext'
require 'packserv/promised_thread'
require 'packserv/server'
require 'packserv/version'

module PackServ
  class << self
    def msgpack_factory
      @fac ||= (
        MessagePack::Factory.new
        .then { |f| MsgPackExt.register_types(f); f }
      )
    end

    def register_type(*args, &block)
      msgpack_factory.register_type(*args, &block)
    end

    def connect(host, port)
      Client.new.connect(host, port)
    end

    def serve(port)
      Server.new.serve(port)
    end
  end
end
