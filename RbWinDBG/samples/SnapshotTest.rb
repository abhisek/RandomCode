require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	cf_count = 0
	cf_count_r = 5
	
	dbg.on_entrypoint do
		puts "Entrypoint Hit - Taking Snapshot"
		
		mem_addr = dbg.get_reg_value(:esp) - 512
		mem_size = 4096
		
		pre_mem_data = dbg.read_process_memory(mem_addr, mem_size)
		
		s = dbg.snapshot_process()
		
		puts "Finished Taking Snapshot"
		puts "Snapshot Thread Count: #{s.snapshot_info[:thread_count]}"
		puts "Snapshot Memory Block Count: #{s.snapshot_info[:memory_block_count]}"
		puts "Snapshot Memory Data Count:  #{s.snapshot_info[:memory_store_count]}"
		
		dbg.bpx(dbg.resolve_name("kernel32.dll!CreateFileW")) do
			if cf_count < cf_count_r
				cf_count += 1
			else
				puts "CreateFileW Hit! - Restoring Snapshot"
				
				post_mem_data = dbg.read_process_memory(mem_addr, mem_size)
				if pre_mem_data != post_mem_data
					puts "BEFORE: MEMORY DATA DOESN'T MATCH"
				else
					puts "BEFORE: MEMORY DATA MATCHES"
				end
				
				dbg.snapshot_restore_process
				
				post_mem_data = dbg.read_process_memory(mem_addr, mem_size)
				if pre_mem_data != post_mem_data
					puts "AFTER: MEMORY DATA DOESN'T MATCH"
				else
					puts "AFTER: MEMORY DATA MATCHES"
				end
				
				exit
			end
		end
		
	end
	
	trap('INT') do
		exit if $aaa
		dbg.snapshot_restore_process
		$aaa = 1
	end
	
	dbg.debug_loop
end