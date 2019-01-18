RSpec.describe PackServ do
  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'all together' do
    before(:all) do
      @server = PackServ.serve(12345)
      puts "started server"

      @server.handler = lambda do |message|
        case message
        when 'hello'
          'hi'
        when 'goodbye'
          'see ya'
        end
      end

      @client = PackServ.connect('localhost', 12345)
      puts "connected"
    end

    after(:all) do
      puts "disconnecting"
      @client.disconnect
      puts "done"
      puts "stopping server"
      @server.stop
      puts "done"
    end

    it 'can communicate' do
      expect(@client.send('hello')).to eq('hi')
      expect(@client.send('goodbye')).to eq('see ya')
    end
  end
end
