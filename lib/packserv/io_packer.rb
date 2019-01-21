module PackServ
  class IOPacker
    extend Forwardable

    def_delegators :@io, :close

    def initialize(io, proto)
      @packer = PackServ.msgpack_factory.packer
      @proto = proto
      @io = io
    end

    def pack(obj)
      obj = @packer.pack(obj).to_s
    rescue StandardError => e
      raise(e)
    else
      write(obj)
    ensure
      @packer.clear
    end

    private

    def frame_length(packed)
      sprintf(@proto::HEADER_FORMAT, packed.bytesize)
    end

    def write(packed)
      @io.write(frame_length(packed) + packed)
    rescue IOError, Errno::EPIPE
      false
    end
  end
end
