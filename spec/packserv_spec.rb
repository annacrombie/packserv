RSpec.describe PackServ do
  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'the client dies' do
  end

  context 'all together' do
    before(:all) do
      start_server
      connect_client
    end

    after(:all) do
      disconnect_client
      stop_server
    end

    it 'can communicate' do
      expect(@client.send('hello')).to eq 'hi'
      expect(@client.send('goodbye')).to eq 'see ya'
    end
  end
end
