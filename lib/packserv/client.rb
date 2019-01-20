module PackServ
  class Client
    def initialize(proto = nil)
      @proto = proto || DefaultProtocol

      @death_handler = @event_handler = ->(_) {}
      @event_queue = Queue.new
      @response_queues = {}
      @outgoing_queue = Queue.new

      @threads = []
      @alive = true
    end

    def on_event(&block)
      @event_handler = block
    end

    def on_die(&block)
      @death_handler = block
    end

    def connect(host, port)
      Concurrent::Promises.future do
        @conn = TCPSocket.new(host, port)

        setup_mailbox(@conn)

        unpacker = IOUnpacker.new(@conn, @proto)

        @threads << PromisedThread.new { unpack(unpacker) }.value
        @threads << PromisedThread.new { dispatch_events }.value

        self
      end
    end

    def disconnect
      @alive = false
      @threads.each(&:kill)
      @conn.close
    end

    def transmit(obj)
      return unless alive?

      rq = @response_queues[obj.object_id] = Queue.new

      @outgoing_queue.push(obj)

      val = rq.pop
      @response_queues.delete(obj.object_id)

      val
    end

    def alive?
      @alive
    end

    private

    def die
      @alive = false
      @death_handler.call(self)
    end

    def dispatch_events
      loop do
        thing = @event_queue.pop
        @event_handler.call(thing)
      end
    end

    def setup_mailbox(server)
      packer = IOPacker.new(server, @proto)

      @threads << PromisedThread.new do
        loop { packer.pack(@proto.create(@outgoing_queue.pop)) }
      end.value
    end

    def unpack(unpacker)
      unpacker.each do |msg|
        case msg['type']
        when 'event'
          @event_queue
        else
          id = @proto.extract_id(msg)

          unless @response_queues.key?(id)
            raise(Exceptions::InvalidId, id)
          else
            @response_queues[id]
          end
        end.push(@proto.extract(msg))
      end

      die
    end
  end
end
