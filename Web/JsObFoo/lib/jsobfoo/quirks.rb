module JsObFoo
  
  class Quirks
    def self.random_encoded_name(name)
      out = ""
      name.unpack('C*').map do |c|
        n = Random.rand(3)

        case n
        when 0
          out << "\\u00#{c.to_s(16)}"
        when 1
          #out << "\\O#{c.to_s(8)}"
          out << c.chr
        else
          out << c.chr
        end
      end

      return out
    end
  end

end