module PackServ
  class Client
    attr_accessor :handler

    def initialize(proto = nil)
      @proto = proto || DefaultProtocol

      @handler = ->(_) {}
      @event_queue = Queue.new
      @response_queue = Queue.new
      @outgoing_queue = Queue.new

      @threads = []
    end

    def connect(host, port)
      Concurrent::Promises.future do
        @conn = TCPSocket.new(host, port)

        @threads << PromisedThread.new { _connect(@conn) }.value
        @threads << PromisedThread.new { dispatch_events }.value

        self
      end
    end

    def disconnect
      @threads.each(&:kill)
      @conn.close
    end

    def transmit(obj)
      @outgoing_queue.push(obj)

      @response_queue.pop
    end

    private

    def dispatch_events
      loop do
        thing = @event_queue.pop
        handler.call(thing)
      end
    end

    def setup_mailbox(server)
      packer = IOPacker.new(server, @proto)

      @threads << PromisedThread.new do
        loop { packer.pack(@proto.create(p @outgoing_queue.pop)) }
      end.value
    end

    def _connect(server)
      setup_mailbox(server)

      IOUnpacker.each_from(server, @proto) do |msg|
        puts "got #{msg}"
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
