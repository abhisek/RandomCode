module JsObFoo

  class Logger
    def self.info(msg)
      puts "[+] #{msg}".green
    end

    def self.verbose(msg)
      puts "[+] #{msg}".cyan
    end

    def self.error(msg)
      puts "[-] #{msg}".red
    end

    def self.warn(msg)
      puts "[*] #{msg}".yellow
    end
  end

end