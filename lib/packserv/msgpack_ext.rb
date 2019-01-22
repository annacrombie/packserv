module PackServ
  module MsgPackExt
    module_function

    def standard_error_packer(err)
      MessagePack.pack({ class: err.class.name, msg: err.to_s })
    end

    def standard_error_unpacker(str)
      h = MessagePack.unpack(str)

      k = const_defined?(h['class']) ? const_get(h['class']) : nil

      if StandardError > k
        k.new(h['msg'])
      else
        Exceptions::InvalidException.new("no such exception: #{h['class']}")
      end
    end

    TYPES = {
      StandardError => {
        prefix: 0x01,
        packer: method(:standard_error_packer),
        unpacker: method(:standard_error_unpacker)
      }
    }

    def register_types(factory)
      TYPES.each do |klass, params|
        factory.register_type(
          params[:prefix],
          klass,
          packer: params[:packer],
          unpacker: params[:unpacker]
        )
      end
    end
  end
end
