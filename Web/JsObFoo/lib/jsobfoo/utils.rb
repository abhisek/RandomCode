module JsObFoo
  class Utils
    def self.random_data(table, count)
      out = ""
      count.times { out << table[ Random.rand(table.size) ] }

      return out
    end

    def self.random_string(n, numbers = false)
      charset =  ("A".."Z").to_a
      charset += ("a".."z").to_a
      charset += ("0".."9").to_a if numbers

      random_data(charset, n)
    end

    def self.random_js_variable(n)
      random_string(1) + random_string(n - 1, true)
    end
  end
end