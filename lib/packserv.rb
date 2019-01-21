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
    def msgpack_factory
      @fac ||= (
        MessagePack::Factory.new
          .then do |f|
            f.register_type(
              0x01,
              StandardError,
              packer: -> (e) { MessagePack.pack({ class: e.class.name, msg: e.to_s }) },
              unpacker: lambda do |s|
                h = MessagePack.unpack(s)

                k = const_defined?(h['class']) ? const_get(h['class']) : nil

                if StandardError > k
                  k.new(h['msg'])
                else
                  Exceptions::InvalidException.new("no such exception: #{h['class']}")
                end
              end
            )

            f
          end
      )
    end

    def connect(host, port)
      Client.new.connect(host, port)
    end

    def serve(port)
      Server.new.serve(port)
    end
  end
end
