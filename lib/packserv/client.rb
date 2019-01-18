module PackServ
  class Client
    attr_accessor :handler

    def initialize(host, port)
      @handler = ->(_) {}
      @event_queue = Queue.new
      @response_queue = Queue.new
    end

    def connect
      server = TCPSocket.new(host, port)

      Thread.new { _connect(server) }
      Thread.new { dispatch_events }

      self
    end

    def send(obj)
      @outgoing.push(obj)

      @response_queue.pop
    end

    private

    def dispatch_events
      loop { handler.(@event_queue.pop) }
    end

    def setup_mailbox(server)
      packer = IOPacker.new(server)
      outgoing = Queue.new

      @mailbox = outgoing
      Thread.new { loop { packer.write(outgoing.pop) } }
    end

    def _connect(server)
      setup_mailbox(server)

      IOUnpacker.each_from(server) do |msg|
        case msg['kind']
        when 'event'
          @event_queue
        else
          @response_queue
        end
      end
    end
  end
end
