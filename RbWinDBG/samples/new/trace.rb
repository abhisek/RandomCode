require 'RbWinDBG'

if __FILE__ == $0
	SymbolProcessor.init()
	dbg = RbWinDBG.start(ARGV[0] || "C:\\Program Files (x86)\\Microsoft Office\\Office14\\Excel.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		sym = SymbolProcessor.new(dbg.process, dbg.process.handle, dbg.process.addrsz)
		excel_base = dbg.get_module("Excel.exe").addr
		puts "Excel Loaded at: 0x%08x" % [excel_base]
		
		oart_base = dbg.get_module("oart.dll").addr
		puts "OART Loaded at: 0x%08x" % [oart_base]

		start_addr = oart_base + 0x001771d2
		end_addr = excel_base + 0x00131470
		
		dbg.bpx(start_addr) do
			puts "Breakpoint hit at start addr: 0x%08x" % [start_addr]
			
			# Trace till end
			prog = ::Metasm::ExeFormat.new(::Metasm::Ia32.new(dbg.process.addrsz))
			loop do
				ip = dbg.get_reg_value(:eip)
				data = dbg.read_memory(ip, 16)
				asm = prog.cpu.decode_instruction(::Metasm::EncodedData.new(data), ip)
				if asm
					ins = "%s: %s" % [sym.address2symbol(ip), asm.instruction.to_s.downcase] 
					puts "> #{ins}"
				else
					puts "** Failed to decode instruction at: 0x%08x" % [ip]
				end
				
				dbg.single_step()
				break if dbg.get_reg_value(:eip) == end_addr
			end
		end
		
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
	end
		
	dbg.start
end