module RbWinDBG

	class SimpleUtils
		def initialize(dbg)
			@dbg = dbg
		end
		
		def read_wstring(addr, max_chars = 4096)
			i = 0
			loop do
				break if @dbg.memory[addr + i, 2].unpack('v').first() == 0
				i += 2
				break if ((i / 2) > max_chars)
			end
			
			@dbg.memory[addr, i].gsub("\x00", "")
		end
		
		def read_string(addr, max_chars = 4096)
			i = 0
			loop do
				break if @dbg.memory[addr + i, 1].unpack('C').first() == 0
				i += 1
				break if i > max_chars
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

end
