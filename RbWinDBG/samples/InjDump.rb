require 'RbWinDBG'

def _msg(m)
	puts("[+] #{m}")
end

def hide_debugger(dbg)
	dbg.bpx(dbg.resolve_name('kernel32.dll!IsDebuggerPresent')) do
		_msg("IsDebuggerPresent() Hit!")
		
		dbg.bpx(dbg.get_stack_arg(0), true) do
			dbg.set_reg_value(:eax, 0)
		end
	end
end

def setup_hooks(dbg)
	$process_map ||= {}
	$wpm_buffers ||= {}
	
	dbg.bpx(dbg.resolve_name('kernel32.dll!OpenProcess')) do
		pid = dbg.get_stack_arg(3)
		
		dbg.bpx(dbg.get_stack_arg(0), true) do
			handle = dbg.get_reg_value(:eax)
			
			if handle != 0
				_msg("OpenProcess(#{pid}) -> #{handle}")
				
				pr = ::Metasm::WinOS.find_process(pid)
				$process_map[handle] = {
					:pid => pid,
					:mod => pr ? pr.modules[0].path : 'unknown'
				}
			end
		end
	end
	
	dbg.bpx(dbg.resolve_name('kernel32.dll!CloseHandle')) do
		handle = dbg.get_stack_arg(1)
	end
	
	dbg.bpx(dbg.resolve_name('kernel32.dll!WriteProcessMemory')) do
		handle = dbg.get_stack_arg(1)
		dst_addr = dbg.get_stack_arg(2)
		src_addr = dbg.get_stack_arg(3)
		size = dbg.get_stack_arg(4)
		
		data = dbg.read_memory(src_addr, size)
		
		$wpm_buffers[handle] ||= 
	end
end

if __FILE__ == $0
	RbWinDBG.init()
	
	dbg = RbWinDBG.start(ARGV[0] || raise("ARGV[0] required!"))
	dbg.on_entrypoint do
		hide_debugger(dbg)
		setup_hooks(dbg)
	end
	
	dbg.start()
end