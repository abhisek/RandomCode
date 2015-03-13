require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start(ARGV[0] || "C:\\Windows\\System32\\Notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		puts "Exe Path: " + dbg.process.modules[0].path
		puts "Current EIP: 0x%08x" % dbg.get_reg_value(:eip)
		
		puts 'Kernel32.DLL path: ' + dbg.resolve_lib_path('kernel32.dll')
		
		puts "CreateFileW: 0x%08x" % dbg.resolve_name('kernel32.dll!CreateFileW')
		puts "GetMessageA: 0x%08x" % dbg.resolve_name('user32.dll!GetMessageA')
		puts "VirtualProtectEx: 0x%08x" % dbg.resolve_name('KERNELBASE.DLL!VirtualProtectEx')
		
		#$stdin.gets
		
		puts "VirtualAlloc(0x60): 0x%08x" % [dbg.virtual_alloc(0x60)]
		
		dbg.bpx(dbg.resolve_name('kernel32.dll!CreateFileW')) do
			#puts 'CreateFileW: %s' % [dbg.utils.read_wstring(dbg.utils.ptr_at(dbg.get_reg_value(:esp) + 4))]
			#puts 'CreateFileW: %s' % [dbg.utils.read_wstring(dbg.get_stack_arg(1)]
			puts 'CreateFileW: %s' % [dbg.utils.read_wstring(dbg.func_param(0))]
		end	
		
		dbg.on_library_load do |lib|
			puts 'LoadLibrary: ' + lib.to_s
		end
		
=begin
Exeption: {:type=>"access violation", :st=>struct _EXCEPTION_RECORD x = {
        .ExceptionCode = 0xC0000005,   // +0
        .ExceptionFlags = 0,   // +4
        .ExceptionRecord = NULL,   // +8
        .ExceptionAddress = 0x3004B3F2,   // +c
        .NumberParameters = 2,   // +10
        .ExceptionInformation = {
                [0] = 0,   // +14
                [1] = 4,   // +18
                [2] = 4,   // +1c
                [3] = 0xFFDFF120,   // +20
                [4] = 0,   // +24
                [5] = 0x862CA190,   // +28
                [6] = 0xC0000005,   // +2c
                [7] = 0,   // +30
                [8] = 24,   // +34
                [9] = 27,   // +38
                [10] = 0xF415ED64,   // +3c
                [11] = 0x804E1FF1,   // +40
                [12] = 0,   // +44
                [13] = 4,   // +48
                [14] = 1,   // +4c
        },
};, :firstchance=>1, :fault_addr=>4, :fault_access=>:r}
=end
		dbg.on_exception do |ei|
			#puts ei.inspect
			puts "Process Exception: #{ei[:type]} (%s) (fault: 0x%08x access: %s)" % 
				[RbWinDBG::NTSTATUS.code_name(ei[:st].ExceptionCode), ei[:fault_addr] || 0, ei[:fault_access] || ""]
				
			$expt ||= 0
			$expt += 1
			
			exit if $expt > 1000
		end
		
=begin
{:st=>struct _CREATE_THREAD_DEBUG_INFO x = {
        .hThread = 0x768,   // +0
        .lpThreadLocalBase = 0x7FFDE000,   // +4
        .lpStartAddress = 0x7C810856,   // +8
};}
=end
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