module RbWinDBG
	
	class SimpleUtils
		def initialize(dbg)
			@dbg = dbg
		end
		
		def read_wstring(addr)
			i = 0
			loop do
				break if @dbg.memory[addr + i, 2].unpack('v').first() == 0
				i += 2
			end
			
			@dbg.memory[addr, i].gsub("\x00", "")
		end
		
		def read_string(addr)
			i = 0
			loop do
				break if @dbg.memory[addr + i, 1].unpack('C').first() == 0
				i += 1
			end
			
			@dbg.memory[addr, i]
		end
		
		def ptr_at(addr)
			@dbg.memory[addr, 4].unpack('V').first()
		end
		
		def ptr_set(addr, v)
			@dbg.memory[addr, 4] = [v].pack('V')
		end
		
		def ptr_set64(addr, v)
			@dbg.memory[addr, 8] = [v].pack('Q')
		end
	end
	
	class SimpleWrapper
	
		def initialize(dbg, pe, process)
			@dbg 			= dbg
			@pe				= pe
			@process		= process
			@utils			= SimpleUtils.new(dbg)
			@modules_map	= {}
			
			on_entrypoint do
				update_module_map!
			end
		end
		
		attr_reader :dbg
		attr_reader :pe
		attr_reader :process
		attr_reader :utils
		
		# Event Handlers
		def on_entrypoint
			if block_given?
				self.bpx(self.entrypoint, true) do
					yield()
				end
			end
		end
		
		def on_library_load
			if block_given?
				self.bpx(self.resolve_name('kernel32.dll!LoadLibraryW')) do
					ret = self.utils.ptr_at(self.get_reg_value(:esp))
					lib = self.utils.read_wstring(self.utils.ptr_at(self.get_reg_value(:esp) + 4))
					self.bpx(ret, true) do
						yield(lib)
					end
				end
			end
		end
		
		#
		# @name: 	lib!funcName
		# @return:	address
		#
		def resolve_name(name)
			lib, name = name.split('!')
			lib_path = resolve_lib_path(lib)
			
			@modules_map[lib_path][name]
		end
		
		def resolve_lib_path(libname)
			@modules_map.keys.find do |s| 
				(File.basename(s).downcase == libname.downcase)
			end
		end
		
		def entrypoint
			@pe.optheader.image_base + @pe.optheader.entrypoint
		end
		
		def bpx(addr, one_time = false)
			@dbg.bpx(addr, one_time) do
				yield()
			end
		end
		
		def bpr(addr_range = {}, one_time = false)
		end
		
		def bpw(addr_range = {}, one_time = false)
		end
		
		def read_memory(addr, len)
			@dbg.memory[addr.to_i, len.to_i]
		end
		
		def write_memory(addr, data)
			@dbg.memory[addr, data.size] = data
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
		
		def update_module_map!
			@process.modules.each do |mod|
				@modules_map[mod.path] ||= {}
				
				mod_pe = Metasm::LoadedPE.load(@dbg.memory[mod.addr, mod.size])
				mod_pe.decode_header
				mod_pe.decode_exports
				
				next if mod_pe.export.nil?
				
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
	
	def self.init
		Metasm::WinOS.get_debug_privilege
	end
end