module PackServ
  class IOUnpacker
    class << self
      def each_from(io, proto)
        iou = IOUnpacker.new(io, proto)

        loop do
          yield(MessagePack.unpack(iou.get_frame))
        end
      end
    end

    def initialize(io, proto)
      @proto = proto
      @io = io
    end

    def get_frame
      @io.read(get_frame_length)
    end

    private

    def get_frame_length
      @io.read(@proto::HEADER_LENGTH).to_i(16)
    end
  end
end
