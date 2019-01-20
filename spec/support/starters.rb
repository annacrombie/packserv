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
    promise = PackServ.serve(port)
    server = promise.value

    server.on_request(&(block_given? ? handler : method(:server_handler)))

    server
  end

  def connect_client(port = 12345, &handler)
    client_events = Queue.new

    promise = PackServ.connect('localhost', port)
    client = promise.value

    client.on_event(&(block_given? ? handler : lambda do |event|
      client_events.push(event)
    end))

    [client_events, client]
  end
end
