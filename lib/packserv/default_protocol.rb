module PackServ
  module DefaultProtocol
    HEADER_LENGTH = 8
    HEADER_FORMAT = '%08x'.freeze

    module_function

    def valid?(msg)
      msg.is_a?(Hash) &&
        msg.keys == %w[ver id type payload] &&
        msg['ver'] == PackServ::VERSION
    end

    def create(obj, type = '', id = nil)
      {
        'ver'     => PackServ::VERSION,
        'id'      => id || obj.object_id,
        'type'    => type,
        'payload' => obj
      }
    end

    def extract_id(msg)
      msg['id']
    end

    def extract(msg)
      msg['payload']
    end
  end
end
