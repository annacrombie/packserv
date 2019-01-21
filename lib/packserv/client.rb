module PackServ
  class Client
    attr_writer :event_handler, :death_handler

    def initialize(proto = nil)
      @proto = proto || DefaultProtocol
      @id = Concurrent::AtomicFixnum.new

      @death_handler = @event_handler = ->(_) {}
      @event_queue = Queue.new
      @response_queues = {}
      @outgoing_queue = Queue.new

      @threads = []
      @alive = false
    end

    def on_event(&block)
      @event_handler = block
    end

    def on_die(&block)
      @death_handler = block
    end

    def connect(host, port)
      return if alive?

      Concurrent::Promises.future do
        @conn = TCPSocket.new(host, port)
        @alive = true

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
      id = next_id

      rq = @response_queues[id] = Queue.new

      @outgoing_queue.push([obj, :request, id])

      val = rq.pop
      @response_queues.delete(id)

      raise val if val.is_a?(StandardError)

      val
    end

    def alive?
      @alive
    end

    private

    def next_id
      @id.increment
    end

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
        loop do
          obj = @outgoing_queue.pop

          begin
            packer.pack(@proto.create(*obj))
          rescue StandardError => e
            response_queue(obj[2]).push(e)
          end
        end
      end.value
    end

    def response_queue(id)
      unless @response_queues.key?(id)
        raise(Exceptions::InvalidId, id)
      else
        @response_queues[id]
      end
    end

    def unpack(unpacker)
      unpacker.each do |msg|
        case @proto.typeof(msg)
        when 'event'
          @event_queue
        when 'response', 'exception'
          response_queue(@proto.extract_id(msg))
        end.push(@proto.extract(msg))
      end

      die
    end
  end
end
