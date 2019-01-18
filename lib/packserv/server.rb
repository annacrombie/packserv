module PackServ
  class Server
    attr_accessor :handler

    def initialize(proto = nil)
      @proto = proto || DefaultProtocol

      @handler = ->(_) {}
      @packers = {}
      @event_queue = Queue.new
      @threads = ThreadGroup.new
    end

    def event(data)
      @event_queue.push(data)
    end

    def serve(port)
      server = TCPServer.new(port)

      @threads.add(Thread.new { _serve(server) })
      @threads.add(Thread.new { deliver_events })

      self
    end

    def stop
      @threads.list.map(&:exit)
    end

    private

    def setup_mailbox(client)
      packer   = IOPacker.new(client, @proto)
      outgoing = Queue.new

      @threads.add(Thread.new do
        loop { packer.pack(@proto.create(outgoing.pop)) }
      end)

      @packers[client.object_id] = packer

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
        @packers.each { |_, k| k.pack(@proto.create(data, 'event')) }
      end
    end

    def _serve(server)
      loop do
        @threads.add(Thread.new(server.accept) { |client| handle(client) })
      end
    end
  end
end
