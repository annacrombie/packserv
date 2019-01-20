module PackServ
  class PromisedThread
    class << self
      def new(*args, &block)
        Concurrent::Promises.future do
          q = Queue.new

          t = Thread.new(*args) do |*args|
            q.push(1)

            block.call(*args)
          end
          q.pop

          t
        end
      end
    end
  end
end
