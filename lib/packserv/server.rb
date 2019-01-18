module PackServ
  class Server
    attr_accessor :handler

    def initialize(port)
      @handler = ->(_) {}
      @mailboxes = {}
      @event_queue = Queue.new
    end

    def server_event(data)
      @event_queue.push(data)
    end

    def serve
      @server_thread = Thread.new { _serve }
      @event_thread = Thread.new { deliver_events }

      self
    end

    def stop
      @server_thread&.exit
      @event_thread&.exit
    end

    private

    def setup_mailbox(client)
      packer   = IOPacker.new(client)
      outgoing = Queue.new

      @mailboxes[client.objectid] = outgoing

      Thread.new { loop { packer.pack(outgoing.pop) } }
    end

    def handle(client)
      setup_mailbox(client)

      IOUnpacker.each_from(client) do |msg|
        response = handler.(msg)

        outgoing.push(response)
      end
    end

    def deliver_events
      loop do
        data = @event_queue.pop
        @mailboxes.each { |_, v| v.push(data) }
      end
    end

    def _serve
      socket = TCPServer.new(port)

      loop do
        Thread.new(socket.accept) { |client| handle(client) }
      end
    end
  end
end
