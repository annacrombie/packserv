module PackServ
  class Client
    attr_accessor :handler

    def initialize
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
      @server.close
      @threads.list.map(&:exit)
    end

    def send(obj)
      @outgoing_queue.push(obj)

      @response_queue.pop
    end

    private

    def dispatch_events
      loop { handler.(@event_queue.pop) }
    end

    def setup_mailbox(server)
      packer = IOPacker.new(server)
      @threads.add(Thread.new { loop { packer.write(@outgoing_queue.pop) } })
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
