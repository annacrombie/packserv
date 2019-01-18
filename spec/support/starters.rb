module Starters
  attr_accessor :server, :client
  def server_handler(message)
    case message
    when 'hello'
      'hi'
    when 'goodbye'
      'see ya'
    end
  end

  def client_event_handler(event)
    @client_events.push(event)
  end

  def last_event
    @client_events.pop
  end

  def start_server(&handler)
    @server = PackServ.serve(12345)

    @server.handler = block_given? ? handler : method(:server_handler)
  end

  def stop_server
    @server.stop
  end

  def connect_client(&handler)
    @client_events = Queue.new
    @client = PackServ.connect('localhost', 12345)
    @client.handler = block_given? ? handler : method(:client_event_handler)
  end

  def disconnect_client
    @client.disconnect
  end
end
