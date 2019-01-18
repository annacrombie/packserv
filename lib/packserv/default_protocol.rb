module PackServ
  module DefaultProtocol
    HEADER_LENGTH = 8
    HEADER_FORMAT = '%08x'.freeze

    module_function

    def create(obj, type = '', id = nil)
      {
        'ver'     => PackServ::VERSION,
        'id'      => id || obj.object_id,
        'type'    => type,
        'payload' => obj
      }
    end

    def extract(msg)
      msg['payload']
    end
  end
end
