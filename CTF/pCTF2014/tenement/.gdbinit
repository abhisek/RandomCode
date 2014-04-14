set follow-fork-mode child
set disassembly-flavor intel
set args ./config.json
break *0x08048B7C
commands
	printf "break:  call    _json_load_file\n"
end

break *0x08048CD8
commands
	printf "break: call    _mmap\n"
end

break *0x08048DFC
commands
	printf "break: call edi\n"
end

define nix
	ni
	x/i $eip
end
