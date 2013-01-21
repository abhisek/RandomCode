require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		
		dbg.bpx(dbg.resolve_name('kernel32.dll!CreateFileW')) do
			puts "Stack Trace: \n"
			dbg.stack_trace.each do |frame|
				puts "0x%08x: %s" % [frame[0], frame[1]]
			end
			puts "--"
			
			dbg.stop
		end	
		
		dbg.on_library_load do |lib|
			puts 'LoadLibrary: ' + lib.to_s
		end

		dbg.on_exception do |ei|
			puts "Process Exception: #{ei[:type]}"
		end
		
		dbg.on_thread_start do |ei|
			puts "New Thread Created #{ei.inspect}"
		end
		
		dbg.on_thread_exit do |ei|
			puts "Thread Exit #{ei.inspect}"
		end
		
		#dbg.stop
	end
		
	dbg.start
end