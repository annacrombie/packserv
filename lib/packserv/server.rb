module PackServ
  class Server
    attr_accessor :handler

    def initialize
      @handler = ->(_) {}
      @mailboxes = {}
      @event_queue = Queue.new
      @threads = ThreadGroup.new
    end

    def server_event(data)
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
      packer   = IOPacker.new(client)
      outgoing = Queue.new

      @threads.add(Thread.new { loop { packer.pack(outgoing.pop) } })

      @mailboxes[client.object_id] = outgoing
    end

    def handle(client)
      outgoing = setup_mailbox(client)

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

    def _serve(server)
      loop do
        @threads.add(Thread.new(server.accept) { |client| handle(client) })
      end
    end
  end
end
