module PackServ
  module Exceptions
    class InvalidId < StandardError
      def initialize(id)
        super("no queue is open for message id #{id}")
      end
    end

    class InvalidMessage < StandardError
      def initialize(msg)
        super(msg)
      end
    end
  end
end
