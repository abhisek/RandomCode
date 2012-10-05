require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		puts "Exe Path: " + dbg.process.modules[0].path
		puts "Current EIP: 0x%08x" % dbg.get_reg_value(:eip)
		
		puts 'Kernel32.DLL path: ' + dbg.resolve_lib_path('kernel32.dll')
		
		puts "CreateFileW: 0x%08x" % dbg.resolve_name('kernel32.dll!CreateFileW')
		puts "GetMessageA: 0x%08x" % dbg.resolve_name('user32.dll!GetMessageA')
		
		puts "VirtualAlloc(0x60): 0x%08x" % [dbg.virtual_alloc(0x60)]
		
		dbg.bpx(dbg.resolve_name('kernel32.dll!CreateFileW')) do
			puts 'CreateFileW: %s' % [dbg.utils.read_wstring(dbg.utils.ptr_at(dbg.get_reg_value(:esp) + 4))]
		end
		
		dbg.on_library_load do |lib|
			puts 'LoadLibrary: ' + lib.to_s
		end
		
		#dbg.stop
	end
		
	dbg.start
end