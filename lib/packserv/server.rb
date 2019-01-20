module PackServ
  class Server
    attr_accessor :handler

    def initialize(proto = nil)
      @proto = proto || DefaultProtocol
      @handler = ->(_) {}
      @conns = {}
      @event_queue = Queue.new
      @threads = []
    end

    def transmit(data)
      @event_queue.push(data)
    end

    def serve(port)
      Concurrent::Promises.future do
        @server = TCPServer.new(port)

        @threads << PromisedThread.new { _serve(@server) }.value
        @threads << PromisedThread.new { deliver_events }.value

        self
      end
    end

    def stop
      @conns.each_value { |c| c.each_value(&:close) }

      @threads.each(&:kill)

      @server.shutdown
      @server.close
    end


    private

    def setup_mailbox(client)
      packer   = IOPacker.new(client, @proto)
      outgoing = Queue.new

      @threads << Thread.new do
        loop { packer.pack(@proto.create(outgoing.pop)) }
      end

      @conns[client.object_id][:packer] = packer

      outgoing
    end

    def handle(client)
      outgoing = setup_mailbox(client)

      IOUnpacker.each_from(client, @proto) do |msg|
        response = handler.(@proto.extract(msg))

        outgoing.push(response)
      end
    end

    def deliver_events
      loop do
        data = @event_queue.pop
        @conns.each { |_, k| k[:packer].pack(@proto.create(data, 'event')) }
      end
    end

    def _serve(server)
      loop do
        @threads <<
          PromisedThread.new(server.accept) do |client|
            @conns[client.object_id] = { io: client }
            handle(client)
          end.value
      end
    rescue IOError
      false
    end
  end
end
