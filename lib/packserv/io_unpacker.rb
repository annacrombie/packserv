module PackServ
  class IOUnpacker
    extend Forwardable

    def_delegators :@io, :close

    def initialize(io, proto)
      @unpacker = PackServ.msgpack_factory.unpacker
      @proto = proto
      @io = io
    end

    def each
      until @io.closed? do
        frame = get_frame

        break if frame.nil? || frame.empty?

        @unpacker.feed(frame)

        obj = @unpacker.unpack
        exception =
          if @proto.valid?(obj)
            nil
          else
            Exceptions::InvalidMessage.new(@proto.invalid_reason(obj))
          end

        yield(obj, exception)
      end
    end

    def get_frame
      @io.read(get_frame_length)
    rescue IOError
      nil
    end

    private

    def get_frame_length
      @io.read(@proto::HEADER_LENGTH).then { |g| g.nil? ? '' : g }.to_i(16)
    rescue IOError, Errno::ECONNRESET
      0
    end
  end
end
