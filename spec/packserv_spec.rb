RSpec.describe PackServ do
  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'in a perfect world' do
    before(:all) { @server = start_server }
    after(:all) { @server.stop }

    context 'the client dies' do
      before(:all) { _, @client_1 = connect_client }

      it 'wont affect the server' do
        @client_1.disconnect
      end
    end

    context 'all together' do
      before(:all) { @events, @client = connect_client }
      after(:all) { @client.disconnect }

      it 'can communicate' do
        expect(client.transmit('hello')).to eq 'hi'
        expect(client.transmit('goodbye')).to eq 'see ya'
      end

      it 'can send events' do
        server.transmit('an event')
        expect(@events.pop).to eq 'an event'
      end
    end
  end

  context 'in the real world' do
    before(:each) { @server_1 = start_server(21212) }
    after(:each) { @server_1.stop }
    it 'can gracefully handle a server crash' do
      _, client = connect_client(21212)

      @server_1.stop

      client.transmit('msg')
    end

    it 'wont get confused' do
      _, client = connect_client(21212)
      @vala = Queue.new
      @valb = Queue.new

      100.times.map do |n|
        q = Queue.new

        [q, Concurrent::Promises.delay { q.push(client.transmit(n)) }, n]
      end.each { |_, p, _| p.touch }.each do |q, _, n|
        puts "checking #{n}"
        expect(q.pop).to eq (n * 2)
      end
    end

    it 'handles invalid messages' do
      _, client = connect_client(21212)
      id = -1

      q = client.instance_variable_get(:@response_queues)[id] = Queue.new

      PackServ::IOPacker.new(
        client.instance_variable_get(:@conn),
        client.instance_variable_get(:@proto)
      ).pack(
         'ver' => 'fake version',
         'id' => id,
         'type' => 'malicious',
         'payload' => nil
      )

      puts q.pop
    end
  end
end
