module PackServ
  module DefaultProtocol
    HEADER_LENGTH = 8
    HEADER_FORMAT = '%08x'.freeze
    VALID_KEYS = %w[ver id type payload]

    module_function

    def invalid_reason(msg)
      if ! msg.is_a?(Hash)
        'message should be a hash'
      elsif msg.keys != VALID_KEYS
        extra_keys = msg.keys.reject { |k| VALID_KEYS.include?(k) }
        missing_keys = VALID_KEYS.reject { |k| msg.keys.include?(k) }

        if !extra_keys.empty? && !missing_keys.empty?
          "message has invalid keys: #{extra_keys.inspect}, and is missing" +
            "keys: #{missing_keys.inspect}"
        elsif !extra_keys.empty?
          "message has invalid keys: #{extra_keys.inspect}"
        elsif !missing_keys.empty?
          "message is missing keys: #{missing_keys.inspect}"
        end
      elsif msg['ver'] != PackServ::VERSION
        "version mismatch, expected #{PackServ::VERSION.inspect}, got #{msg['ver'].inspect}"
      end
    end

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
