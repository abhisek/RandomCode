CC = g++
CFLAGS = -O0 -m32 -ggdb
all: bug sample
bug:
	g++ $(CFLAGS) -o bug bug.cpp
sample:
	g++ $(CFLAGS) -o sample sample.cpp

.PHONY: clean
clean:
	-rm bug sample
	-rm -rf *.dSYM
