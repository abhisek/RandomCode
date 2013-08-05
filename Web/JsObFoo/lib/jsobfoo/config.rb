require 'optparse'

module JsObFoo

  class Config
    def initialize()
      @config = {
        :input_file => nil,
        :ouptput_file => nil,
        :verbose => false,
        :obfoo_min_var_size => 10,
        :obfoo_max_var_size => 30,
        :compress => false
      }
    end

    def input_file
      @config[:input_file]
    end

    def verbose?
      !!@config[:verbose]
    end

    def compress?
      !!@config[:compress]
    end

    def parse!
      opt_p = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"

        opts.on("-i", "--input [FILE]", "Javascript source file to obfuscate") do |file|
          @config[:input_file] = file.to_s
        end

        opts.on("-o", "--output [FILE]", "File to write obfuscated Javascript source") do |file|
          @config[:output_file] = file.to_s
        end

        opts.on("-z", "--compress", "Compress generated Javascript source") do
          @config[:compress] = true
        end

        opts.on("-v", "--verbose", "Show verbose messages") do
          @config[:verbose] = true
        end

        opts.on("-C", "--console", "Start IRB console") do
          IRB.start(__FILE__)
          exit(1)
        end
      end

      if ARGV.size.zero?
        puts opt_p
        exit(1)
      end

      opt_p.parse!(ARGV)
    end
  end

end