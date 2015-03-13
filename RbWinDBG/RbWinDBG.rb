raise "Unsupported Ruby version!" if RUBY_VERSION !~ /^1\.9/

$:.unshift(File.join(File.dirname(__FILE__), 'lib-ext'))
$:.unshift(File.join(File.dirname(__FILE__), 'lib-ext', 'metasm'))
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'metasm'
require 'rbDbg'
require 'rbDbgUtils'
require 'rbDbgSnapshot'
require 'rbMiniDump' rescue nil
require 'ntstatus'
require 'symbols'

$symbols_dir = "C:\\Symbols"
class SymbolProcessor < ::Grinder::Core::Debug::ProcessSymbols
end

$VERBOSE = false
$DEBUG = false

module RbWinDBG
	VERSION	= '0.1'
end

