module PackServ
  class IOUnpacker
    extend Forwardable

    def_delegators :@io, :close

    class << self
      def each_from(io, proto)
        iou = IOUnpacker.new(io, proto)

        loop do
          frame = iou.get_frame

          break if frame.nil? || frame.empty?

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
    rescue IOError
      nil
    end

    private

    def get_frame_length
      @io.read(@proto::HEADER_LENGTH).then { |g| g.nil? ? '' : g }.to_i(16)
    rescue IOError
      0
    end
  end
end
