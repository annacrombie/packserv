module Starters
  def default_handler(message)
    case message
    when 'hello'
      'hi'
    when 'goodbye'
      'see ya'
    end
  end

  def start_server(&handler)
    @server = PackServ.serve(12345)

    @server.handler = block_given? ? handler : method(:default_handler)
  end

  def stop_server
    @server.stop
  end

  def connect_client
    @client = PackServ.connect('localhost', 12345)
  end

  def disconnect_client
    @client.disconnect
  end
end
