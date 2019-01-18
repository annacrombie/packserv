module PackServ
  class IOUnpacker
    class << self
      def each_from(io)
        iou = IOUnpacker.new(io)

        loop do
          yield(MessagePack.unpack(iou.get_frame))
        end
      end
    end

    def initialize(io)
      @io = io
    end

    def get_frame
      @io.read(get_frame_length)
    end

    private

    def get_frame_length
      @io.read(Protocol::HEADER_LENGTH).to_i(16)
    end
  end
end
