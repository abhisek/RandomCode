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
		
		def memory
			@dbg.memory
		end
		
		# Clears Metasm Page Cache
		def memory_invalidate_cache
			@dbg.memory.invalidate
		end
		
		# Returns VirtualString if len > 4096 instead of plain Ruby string
		# Metasm implements PageCache around it
		def read_memory_cached(add, len)
			@dbg.memory[addr.to_i, len.to_i]
		end
		
		def read_memory(addr, len)
			# For large read, Metasm may cache and return WindowsRemoteString
			mem = @dbg.memory[addr.to_i, len.to_i]
			mem = mem.realstring() unless mem.is_a?(String)
			
			mem
		end
		
		def write_memory(addr, data)
			@dbg.memory[addr, data.size] = data
		end
		
		# This is required because usual memory read may be cached
		# len should be page aligned
		def read_process_memory(addr, len)
			buffer = [0].pack('C') * len
			return nil if ::Metasm::WinAPI.readprocessmemory(@process.handle, addr, buffer, len, 0) == 0
			buffer
		end
		
		def write_process_memory(addr, data)
			::Metasm::WinAPI.writeprocessmemory(@process.handle, addr, data, data.size, nil)
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
		
		def virtual_free(addr, size = 0, free_type = ::Metasm::WinAPI::MEM_RELEASE)
			Metasm::WinAPI.virtualfreeex(@process.handle, addr, size, free_type)
		end
		
		def execute_code(code)
			Metasm::WinOS.inject_run_shellcode(@process, code.to_s)
		end
		
		def current_context
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
		
		# Returns thread ids
		def threads
			@process.threads
		end
		
		def get_thread(tid)
			Metasm::WinOS::Thread.new(tid.to_i, nil, @process)
		end
		
		def get_thread_handle(tid)
			self.get_thread(tid).handle()
		end
		
		def get_thread_context(tid)
			ctx = self.get_thread(tid).context()
			ctx.update()	# This actually executes the GetThreadContext
			
			ctx
		end
		
		def suspend_all_threads
			self.threads.each do |tid|
				self.get_thread(tid).suspend()
			end
		end
		
		def resume_all_threads
			self.threads.each do |tid|
				self.get_thread(tid).resume()
			end
		end
		
		def set_thread_context(tid, context)
			# FAILS! for WOW64
			::Metasm::WinAPI.setthreadcontext(self.get_thread_handle(tid), context)
		end
		
		def single_step
			@dbg.singlestep
		end
		
		def start
			@dbg.run_forever
		end
		
		def debug_loop
			self.start()
		end
		
		def run_once
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
		
		def list_modules
			::Metasm::WinOS.list_modules(@process.pid)
		end
		
		def get_module(dll_name)
			self.list_modules.each do |mod|
				next if mod.path.to_s.empty?
				
				return mod if File.basename(mod.path).downcase == dll_name.to_s.downcase
			end
			
			nil
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
		
		def disassemble(data)
			# 
			# This will return an instance of Metasm::Disassembler which can be used as:
			#
			#	irb(main):029:0> dasm.decoded
			#	=> {0=>0 jmp 0eh ; x:0eh}
			#	
			#	dasm.decode is a Hash with key being the addr and value being a
			#	Metasm::DecodedInstruction
			#
			::Metasm::Shellcode.disassemble(Metasm::Ia32.new, data)
		end
		
		def snapshot_process
			@snapshot = Win32ProcessSnapshot.new(self)
			@snapshot.snapshot!
			
			return @snapshot
		end
		
		def snapshot_restore_process(snapshot = nil)
			s = snapshot || @snapshot
			s.restore!
			
			return s
		end
	end
	
	def self.attach(pid)
		process = Metasm::WinOS.find_process(pid.to_i)
		dbg = process.debugger()
		pe = Metasm::LoadedPE.load(dbg.memory[process.modules[0].addr, process.modules[0].size])
		pe.decode_header
		pe.decode_imports
		
		sdbg = SimpleWrapper.new(dbg, pe, process)
		sdbg.update_module_map!
		
		sdbg
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