CC=gcc
CFLAGS=-ggdb
LDFLAGS=-ggdb -shared

all: crash.o
	-gcc -o crash.so ${LDFLAGS} crash.o

.PHONY: clean
clean:
	-rm crash.o
	-rm crash.so


