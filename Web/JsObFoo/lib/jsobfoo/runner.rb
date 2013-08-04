module JsObFoo
  
  class Runner
    def initialize(config)
      @config = config
      @mm = ::JsObFoo::ModuleManager.new(self)
    end

    def run
      begin
        run_obfoo()
      rescue => e
        msg_err("Exception: #{e.message}")
      end
    end

    def get_parser()
      @parser ||= RKelly::Parser.new
    end

    def get_ast()
      @ast ||= get_parser.parse(File.read(@config.input_file))
    end

    def msg_err(m)
      ::JsObFoo::Logger.error(m)
    end

    def msg_info(m)
      ::JsObFoo::Logger.info(m)
    end

    def msg_verbose(m)
      ::JsObFoo::Logger.verbose(m) if @config.verbose?
    end

    private

    def run_obfoo
      msg_info("Parsing input source")
      ast = get_ast()

      msg_info("Running modules")
      @mm.run_modules(ast)

      final_source = ast.to_ecma
      final_source = js_compress(final_source) if @config.compress?

      puts final_source
    end

    def js_compress(js_str)
      msg_info("Compressing Javascript source")

      u = ::Uglifier.new({:mangle => false})
      u.compile(js_str)
    end
  end

end