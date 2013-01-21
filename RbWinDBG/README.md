RbWinDBG
=========

*Win32 scriptable debugger in Ruby using Metasm API.*

Requirements
------------

Metasm library needs to be in: C:\Lib\metasm

Introduction
------------

```ruby
require 'RbWinDBG'

if __FILE__ == $0
	# Platform specific initialization
	RbWinDBG.init()
	
	# Create Debugger Object (optionally can be attached as well)
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	# Execute till entrypoint and set breakpoints (EP callback)
	dbg.on_entrypoint do
	
		# Set breakpoint (BP callback)
		dbg.bpx(dbg.resolve_name('kernel32.dll!CreateFileW')) do
			puts("CreateFileW !!")
		end
	end
	
	# Start debugger loop
	dbg.start()
end
```

RbWinDBG internally maintains a map of dynamically loaded modules (DLL) and their exported function names and corresponding address in memory. In order to resolve the address of a function by name, it is imperative that the library is already loaded and processed by RbWinDBG. Due to this reason we set the breakpoint in the above example after entrypoint is hit.

Common Usage
-----------

```ruby
require 'RbWinDBG'

if __FILE__ == $0
	RbWinDBG.init()
	
	dbg = RbWinDBG.start("C:\\Windows\\System32\\notepad.exe")
	
	puts "Process Handle: 0x%08x" % [dbg.process.handle]
	puts "EP: 0x%08x" % [dbg.entrypoint]
	
	dbg.on_entrypoint do
		puts "Exe Path: " + dbg.process.modules[0].path
		puts "Current EIP: 0x%08x" % dbg.get_reg_value(:eip)
		
		puts 'Kernel32.DLL path: ' + dbg.resolve_lib_path('kernel32.dll')
		
		puts "CreateFileW: 0x%08x" % dbg.resolve_name('kernel32.dll!CreateFileW')
		puts "GetMessageA: 0x%08x" % dbg.resolve_name('user32.dll!GetMessageA')
		
		puts "VirtualAlloc(0x60): 0x%08x" % [dbg.virtual_alloc(0x60)]
		
		dbg.bpx(dbg.resolve_name('kernel32.dll!CreateFileW')) do
			puts 'CreateFileW: %s' % [dbg.utils.read_wstring(dbg.utils.ptr_at(dbg.get_reg_value(:esp) + 4))]
		end	
		
		dbg.on_library_load do |lib|
			puts 'LoadLibrary: ' + lib.to_s
		end

		dbg.on_exception do |ei|
			puts "Process Exception: #{ei[:type]}"
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
```
