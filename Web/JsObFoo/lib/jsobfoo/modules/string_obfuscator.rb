module JsObFoo

  class StringObfuscator
    def initialize()
      @mm = ::JsObFoo::ModuleManager.get_instance()
    end

    def run(ast, node)
      @mm.msg_verbose("Running module: #{self.class.to_s} on #{node.class}")
      node.value = js_obfuscate_string(node.value)
    end

    private

    def js_obfuscate_string(str)
      n = Random.rand(2)
      case n
      when 0
        js_string_charcode_obfuscator(str)
      when 1
        js_string_encoding_obfuscator(str)
      end
    end

    def js_string_charcode_obfuscator(str)
      "String.fromCharCode(" + str.unpack('C*').map {|e| e.to_s }.join(",") + ")"
    end

    def js_string_encoding_obfuscator(str)
      new_str = str.unpack('C*').map do |c|
        n = Random.rand(2)
        if n == 0
          "\\x%02x" % [c]
        else
          "\\u00#{c.to_s(16)}"
        end
      end.join()

      "\"" + new_str + "\""
    end
  end

end

mi = ::JsObFoo::StringObfuscator.new()

::JsObFoo::ModuleManager.get_instance().
  register_node_module(
    ::RKelly::Nodes::StringNode,
    mi
  )