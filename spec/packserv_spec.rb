RSpec.describe PackServ do
  before(:all) { start_server }
  after(:all) { stop_server }

  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'the client dies' do
    before(:all) { connect_client }

    it 'wont affect the server' do
      disconnect_client
    end
  end

  context 'all together' do
    before(:all) { connect_client }
    after(:all) { disconnect_client }

    it 'can communicate' do
      expect(client.send('hello')).to eq 'hi'
      expect(client.send('goodbye')).to eq 'see ya'
    end

    it 'can send events' do
      server.event('an event')
      expect(last_event).to eq 'an event'
    end
  end
end
