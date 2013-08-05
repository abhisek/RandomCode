require 'rubygems'
require 'bundler'
require 'irb'

require File.join(File.dirname(__FILE__), 'lib', 'jsobfoo')
Bundler.require(:default)

if __FILE__ == $0
  config = ::JsObFoo::Config.new
  config.parse!

  JsObFoo::Runner.new(config).run()
end
