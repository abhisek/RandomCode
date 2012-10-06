$:.unshift("C:\\Lib\\metasm")
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'metasm'
require 'rbDbg'
require 'rbDbgUtils'
require 'rbMiniDump'

$VERBOSE = false
$DEBUG = false

module RbWinDBG
	VERSION	= '0.1'
end

