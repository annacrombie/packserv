module PackServ
  class IOUnpacker
    class << self
      def each_from(io, proto)
        iou = IOUnpacker.new(io, proto)

        loop do
          frame = iou.get_frame

          break if frame.empty?

          yield(MessagePack.unpack(frame))
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
      @io.read(@proto::HEADER_LENGTH).then { |g| g.nil? ? '' : g }.to_i(16)
    end
  end
end
