RSpec.describe PackServ do
  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'in a perfect world' do
    before(:all) { @server = start_server }
    after(:all) { @server.stop }

    context 'the client dies' do
      before(:all) { _, @client = connect_client }

      it 'wont affect the server' do
        @client.disconnect
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
    before(:all) { @server_1 = start_server(21212) }
    it 'can gracefully handle a server crash' do
      client = connect_client(21212)

      @server_1.stop

      client.transmit('msg')
    end
  end
end
