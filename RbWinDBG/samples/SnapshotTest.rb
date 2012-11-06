require 'RbWinDBG'

if __FILE__ == $0
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		puts "Entrypoint Hit - Taking Snapshot"
		
		s = dbg.snapshot_process()
		
		puts "Finished Taking Snapshot"
		puts "Snapshot Thread Count: #{s.snapshot_info[:thread_count]}"
		puts "Snapshot Memory Block Count: #{s.snapshot_info[:memory_block_count]}"
		puts "Snapshot Memory Data Count:  #{s.snapshot_info[:memory_store_count]}"
		
	end
	
	trap('INT') do
		exit if $aaa
		dbg.snapshot_restore_process
		$aaa = 1
	end
	
	dbg.debug_loop
end