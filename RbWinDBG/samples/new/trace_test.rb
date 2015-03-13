require 'RbWinDBG'

if __FILE__ == $0
	SymbolProcessor.init()
	dbg = RbWinDBG.start(ARGV[0] || "C:\\Windows\\System32\\Notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		sym = SymbolProcessor.new(dbg.process, dbg.process.handle, dbg.process.addrsz)
		
		dbg.on_library_load do |lib|
			puts 'LoadLibrary: ' + lib.to_s
		end
		
		dbg.on_exception do |ei|
			if ei[:type] =~ /access violation/
				puts ei.inspect
				dbg.stop()
			end
		end
		
		dbg.on_thread_start do |ei|
			puts "New Thread Created #{ei.inspect}"
		end
		
		dbg.on_thread_exit do |ei|
			puts "Thread Exit #{ei.inspect}"
		end
		
		prog = ::Metasm::ExeFormat.new(::Metasm::Ia32.new(dbg.process.addrsz))
		sym.refresh_symbols()
		
		loop do
			ip = dbg.get_reg_value(:eip)
			data = dbg.read_memory(ip, 16)
			asm = prog.cpu.decode_instruction(::Metasm::EncodedData.new(data), ip)
			if asm
				# Thanks Stephen Fewer
				assembly = asm.instruction.to_s.downcase
				if asm.opcode.name == 'call' and asm.instruction.args[0] and asm.instruction.args[0].respond_to?(:rexpr )
					calladdr = asm.instruction.args[0].rexpr
					if calladdr
						callsym = sym.address2symbol(calladdr)
						assembly = "call #{callsym}" unless callsym.to_s.empty?
					end
				end
				ins = "%-48s: %s" % [sym.address2symbol(ip), assembly] 
				puts "> #{ins}"
			else
				puts "** Failed to decode instruction at: 0x%08x" % [ip]
			end
			
			dbg.single_step()
		end
	end
		
	dbg.start
end