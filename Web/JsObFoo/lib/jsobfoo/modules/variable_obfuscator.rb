module JsObFoo

  class VariableNameObfuscator
    def initialize()
      @mm = ::JsObFoo::ModuleManager.get_instance()
    end

    def run(ast, node)
      @var_map ||= {}
      @fun_map ||= {}

      @mm.msg_verbose("Running module: #{self.class.to_s} on #{node.class}")

      if node.is_a?(::RKelly::Nodes::FunctionDeclNode)
        @fun_map[node.value] ||= ::JsObFoo::Utils.random_js_variable(10)
        node.value = @fun_map[node.value]
      elsif node.is_a?(::RKelly::Nodes::FunctionCallNode)
        name = node.value.value   # node.value -> ResolveNode
        # Ensure we mangle locally defined function names only
        if @fun_map[name]
          node.value.value = @fun_map[name]
        end
      elsif node.is_a?(::RKelly::Nodes::ResolveNode)
        node.value = @var_map[node.value] unless @var_map[node.value].nil?
      else
        orig_name = node.name
        orig_sig  = orig_name

        name = ::JsObFoo::Utils.random_js_variable(10)
        name = ::JsObFoo::Quirks.random_encoded_name(name)
        node.name = name

        @var_map[orig_sig] = name
      end
    end
  end

end

mi = ::JsObFoo::VariableNameObfuscator.new()

::JsObFoo::ModuleManager.get_instance().
  register_node_module(
    ::RKelly::Nodes::VarDeclNode,
    mi
  )

::JsObFoo::ModuleManager.get_instance().
  register_node_module(
    ::RKelly::Nodes::ResolveNode,
    mi
  )

  ::JsObFoo::ModuleManager.get_instance().
  register_node_module(
    ::RKelly::Nodes::FunctionDeclNode,
    mi
  )

  ::JsObFoo::ModuleManager.get_instance().
  register_node_module(
    ::RKelly::Nodes::FunctionCallNode,
    mi
  )