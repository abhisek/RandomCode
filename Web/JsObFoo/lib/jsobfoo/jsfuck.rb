require 'execjs'

class JsFuck
  def initialize()
    @context = ::ExecJS.compile(File.read(File.join(File.dirname(__FILE__), "jsfuck.js")))
  end

  def fsck(str, wrap_eval = false)
    #@context.exec(js % [str])
    @context.call("JSFuck.encode", str, wrap_eval)
  end
end
