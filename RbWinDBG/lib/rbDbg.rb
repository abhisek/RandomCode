module RbWinDBG
	
	class SimpleWrapper
	
		def initialize(dbg, pe, process)
			$rbWinDbgConfig ||= {}
			
			@dbg 						= dbg
			@pe							= pe
			@process					= process
			@utils						= SimpleUtils.new(dbg)
			@modules_map				= {}
			@queued_name_breakpoints 	= []
			
			on_entrypoint do
				update_module_map!
				
				on_library_load do
					update_module_map!
					set_queued_name_breakpoints!
				end
			end
			
			@dbg.set_log_proc(nil) do
				# Ignore Logs from Metasm
			end unless $rbWinDbgConfig[:metasm_debug]
		end
		
		attr_reader :dbg
		attr_reader :pe
		attr_reader :process
		attr_reader :utils
		
		# Event Handlers
		def on_entrypoint(&block)
			self.bpx(self.entrypoint, true) do
				block.call()
			end
		end
		
		def on_library_load(&block)
			self.bpx(self.resolve_name('kernel32.dll!LoadLibraryW')) do
				ret = self.utils.ptr_at(self.get_reg_value(:esp))
				lib = self.utils.read_wstring(self.utils.ptr_at(self.get_reg_value(:esp) + 4))
				self.bpx(ret, true) do
					block.call(lib)
				end
			end
		end
		
		def on_exception(&block)
			@dbg.callback_exception = proc do |h|
				block.call(h) if h[:type].to_s !~ /breakpoint/i
			end
		end
		
		def on_process_start(&block)
			@dbg.callback_newprocess = proc do |h|
				block.call(h)
			end
		end
		
		def on_process_exit(&block)
			@dbg.callback_endprocess = proc do |h|
				block.call(h)
			end
		end
		
		def on_thread_start(&block)
			@dbg.callback_newthread = proc do |h|
				block.call(h)
			end
		end
		
		def on_thread_exit(&block)
			@dbg.callback_endthread = proc do |h|
				block.call(h)
			end
		end
		
		def on_debug_string(&block)
			@dbg.callback_debugstring = proc do |h|
				block.call(h)
			end
		end
		
		#
		# @name: 	lib!funcName
		# @return:	address
		#
		def resolve_name(name)
			lib, name = name.split('!')
			lib_path = resolve_lib_path(lib)
			
			return @modules_map[lib_path][name] unless @modules_map[lib_path].nil?
			nil
		end
		
		def resolve_lib_path(libname)
			@modules_map.keys.find do |s| 
				(File.basename(s).downcase == libname.downcase)
			end
		end
		
		def entrypoint
			# TODO: Fetch Image Base from PEB
			@pe.optheader.image_base + @pe.optheader.entrypoint
		end
		
		def qbpx(name, one_time = false, &block)
			addr = self.resolve_name(name)
			if addr.nil?
				@queued_name_breakpoints << {:name => name, :proc => block }
			else
				self.bpx(addr, one_time) { block.call }
			end
		end
		
		def bpx(addr, one_time = false, &block)
			addr = self.resolve_name(addr) if addr.is_a?(String)
			@dbg.bpx(addr, one_time, nil) { block.call } unless addr.nil?
		end
		
		def bpr(addr, mLen = 1, one_time = false, &block)
			addr = self.resolve_name(addr) if addr.is_a?(String)
			@dbg.hwbp(addr, :r, mLen, nil) { block.call } unless addr.nil?
		end
		
		def bpw(addr, mLen = 1, one_time = false, &block)
			addr = self.resolve_name(addr) if addr.is_a?(String)
			@dbg.hwbp(addr, :w, mLen, nil) { block.call } unless addr.nil?
		end
		
		def stack_trace(depth = 500)
			@dbg.stacktrace(depth)
		end
		
		def read_memory(addr, len)
			@dbg.memory[addr.to_i, len.to_i]
		end
		
		def write_memory(addr, data)
			@dbg.memory[addr, data.size] = data
		end
		
		def minidump(path)
			::RbWinDBG::DbgHelp.create_minidump(@process.pid, path)
		end
		
		def virtual_alloc(size, loc = nil, alloc_type = nil, prot = nil)
			loc ||= 0
			alloc_type ||= Metasm::WinAPI::MEM_COMMIT | Metasm::WinAPI::MEM_RESERVE
			prot ||= Metasm::WinAPI::PAGE_EXECUTE_READWRITE
			
			Metasm::WinAPI.virtualallocex(@process.handle, loc, size.to_i, alloc_type, prot)
		end
		
		def execute_code(code)
			Metasm::WinOS.inject_run_shellcode(@process, code.to_s)
		end
		
		def context
			@dbg.ctx
		end

		def get_stack_arg(n)
			self.utils.ptr_at(self.get_reg_value(:esp) + (n * 4))
		end
		
		def registers
		end
		
		def get_reg_value(reg)
			@dbg.get_reg_value(reg.to_sym)
		end
		
		def set_reg_value(reg, value)
			@dbg.set_reg_value(reg.to_sym, value.to_i)
		end
		
		def threads
			@process.threads
		end
		
		def get_thread(tid)
			Metasm::WinOS::Thread.new(tid.to_i)
		end
		
		def start
			@dbg.run_forever
		end
		
		def debug_loop
			self.start()
		end
		
		def loop
			self.start()
		end
		
		def stop
			@dbg.kill
		end
		
		def detach
			@dbg.detach
		end
		
		def set_queued_name_breakpoints!
			@queued_name_breakpoints.each do |qnbp|
				# TODO: Set the breakpoint and delete the entry
			end
		end
		
		def update_module_map!
			@process.modules.each do |mod|
				next if mod.path.nil?
				next unless @modules_map[mod.path].nil?
				
				@modules_map[mod.path] = {}
				
				mod_pe = Metasm::LoadedPE.load(@dbg.memory[mod.addr, mod.size])
				mod_pe.decode_header
				mod_pe.decode_exports
				
				next if mod_pe.export.nil?
				next if mod_pe.export.exports.nil?
				
				mod_pe.export.exports.each do |exp|
					next if exp.name.nil? and exp.ordinal.nil?
					next if exp.target_rva.nil?
					
					@modules_map[mod.path][exp.name || "ORD_#{exp.ordinal}"] = mod.addr + exp.target_rva
				end
			end
		end
	end
	
	def self.attach(pid)
		process = Metasm::WinOS.find_process(pid.to_i)
		dbg = process.debugger()
		pe = Metasm::LoadedPE.load(dbg.memory[process.modules[0].addr, process.modules[0].size])
		pe.decode_header
		pe.decode_imports
		
		SimpleWrapper.new(dbg, pe, process)
	end
	
	def self.start(path)
		pe = Metasm::PE.decode_file(path)
		process = Metasm::WinOS.create_process(path)
		dbg = process.debugger()
		
		SimpleWrapper.new(dbg, pe, process)
	end
	
	def self.init(rbWinDbgConfig =
					{
						:metasm_debug => false
					}
				 )
		
		$rbWinDbgConfig = rbWinDbgConfig
		
		Metasm::WinOS.get_debug_privilege
	end
end