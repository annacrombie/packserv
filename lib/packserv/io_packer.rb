module PackServ
  class IOPacker
    def initialize(io, proto)
      @proto = proto
      @io = io
    end

    def pack(obj)
      write(MessagePack.pack(obj))
    end

    private

    def frame_length(packed)
      sprintf(@proto::HEADER_FORMAT, packed.bytesize)
    end

    def write(packed)
      @io.write(frame_length(packed) + packed)
    end
  end
end
