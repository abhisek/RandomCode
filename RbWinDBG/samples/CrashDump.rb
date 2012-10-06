$:.unshift("C:\\Documents and Settings\\User1\\Desktop\\RandomCode\\RandomCode\\RbWinDBG")
require 'RbWinDBG'

$exe_path = "C:\\Program Files\\Microsoft Office\\Office12\\EXCEL.EXE"

if __FILE__ == $0
	RbWinDBG.init({:metasm_debug => true})
	
	dbg = RbWinDBG.start($exe_path)
	dbg.on_entrypoint do
		puts "ENTRYPOINT HIT!"
	end

	dbg.on_exception do |ei|
		puts "Exeption: #{ei.inspect}"
		dbg.stop if ei[:type] == 'access violation'
	end
	
	puts 'Starting Debug Loop'
	dbg.start
end