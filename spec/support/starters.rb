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

  def start_server(port = 12345, &handler)
    server = PackServ.serve(port)

    server.handler = block_given? ? handler : method(:server_handler)

    server
  end

  def connect_client(port = 12345, &handler)
    client_events = Queue.new

    client = PackServ.connect('localhost', port)
    client.handler = block_given? ? handler : lambda do |event|
      client_events.push(event)
    end

    [client_events, client]
  end
end
