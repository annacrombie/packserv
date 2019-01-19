module PackServ
  class Client
    attr_accessor :handler

    def initialize(proto = nil)
      @proto = proto || DefaultProtocol

      @handler = ->(_) {}
      @event_queue = Queue.new
      @response_queue = Queue.new
      @outgoing_queue = Queue.new

      @threads = ThreadGroup.new
    end

    def connect(host, port)
      @server = TCPSocket.new(host, port)

      @threads.add(Thread.new { _connect(@server) })
      @threads.add(Thread.new { dispatch_events })

      self
    end

    def disconnect
      @threads.list.map(&:exit)
      @server.close
    end

    def transmit(obj)
      @outgoing_queue.push(obj)

      @response_queue.pop
    end

    private

    def dispatch_events
      loop { handler.(@event_queue.pop) }
    end

    def setup_mailbox(server)
      packer = IOPacker.new(server, @proto)
      @threads.add(Thread.new do
        loop { packer.pack(@proto.create(@outgoing_queue.pop)) }
      end)
    end

    def _connect(server)
      setup_mailbox(server)

      IOUnpacker.each_from(server, @proto) do |msg|
        case msg['type']
        when 'event'
          @event_queue
        else
          @response_queue
        end.push(@proto.extract(msg))
      end
    end
  end
end
