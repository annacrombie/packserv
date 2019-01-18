RSpec.describe PackServ do
  it 'has a version number' do
    expect(PackServ::VERSION).not_to be nil
  end

  context 'all together' do
    server = PackServ.serve(12345)

    server.handler = lambda do |message|
      case message
      when 'hello'
        'hi'
      when 'goodbye'
        'see ya'
      end
    end

    client = PackServ.connect('localhost', 12345)

    it 'can communicate' do
      expect(client.send('hello')).to eq('hi')
      expect(client.send('goodbye')).to eq('see ya')
    end
  end
end
