require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		puts "Entrypoint Hit - Taking Snapshot"
		
		pre_snapshot_data = {
			:esp => dbg.get_reg_value(:esp),
			:eip => dbg.get_reg_value(:eip),
			:esp_data => dbg.memory[dbg.get_reg_value(:esp) - 32, 64]
		}
		
		s = dbg.snapshot_process()
		
		puts "Finished Taking Snapshot"
		puts "Snapshot Thread Count: #{s.snapshot_info[:thread_count]}"
		puts "Snapshot Memory Block Count: #{s.snapshot_info[:memory_block_count]}"
		puts "Snapshot Memory Data Count:  #{s.snapshot_info[:memory_store_count]}"
		
		dbg.bpx(dbg.resolve_name("kernel32.dll!CreateFileW")) do
			puts "CreateFileW Hit! - Restoring Snapshot"
			dbg.snapshot_restore_process
			
			post_snapshot_data = {
				:esp => dbg.get_reg_value(:esp),
				:eip => dbg.get_reg_value(:eip),
				:esp_data => dbg.memory[dbg.get_reg_value(:esp) - 32, 64]
			}
			
			if pre_snapshot_data != post_snapshot_data
				puts "DATA DOES NOT MATCH!"
				puts "----- PRE ----"
				puts pre_snapshot_data.inspect
				puts "--------------"
				puts "----- POST ----"
				puts post_snapshot_data.inspect
				puts "----------------"
				#exit
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