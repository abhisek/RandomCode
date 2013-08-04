def require_module(name)
  require File.join(File.dirname(__FILE__), 'modules', name)
end

module JsObFoo

  class ModuleManager
    
    def self.get_instance()
      return $module_manager_instance
    end

    def initialize(runner)
      @runner = runner
      @node_modules_map = {}

      $module_manager_instance = self

      require_module('variable_obfuscator')
      require_module('string_obfuscator')
    end

    def run_modules(ast)
      ast.each do |node|
        #puts "#{node.class}: #{node.value.class}"
        run_node_modules(ast, node)
      end
    end

    def msg_info(m)
      @runner.msg_info(m)
    end

    def msg_verbose(m)
      @runner.msg_verbose(m)
    end

    def register_node_module(node_type, module_instance)
      @node_modules_map[node_type] ||= []
      @node_modules_map[node_type].push(module_instance)
    end

    def run_node_modules(ast, node)
      m = @node_modules_map[node.class]
      
      unless m.nil? or m.size.zero?
        m.each {|mod| mod.run(ast, node) }
      end
    end

  end

end