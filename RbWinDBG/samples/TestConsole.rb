require 'RbWinDBG'
require 'irb'

if __FILE__ == $0
	$dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	IRB.start(__FILE__)
end