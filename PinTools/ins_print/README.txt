For 32bit cross compilation to work:
sudo apt-get install gcc-4.8-multilib g++-4.8-multilib

Default 64bit compile:

PIN_ROOT=/home/user1/Tools/pin/pin-2.14-71313-gcc.4.4.7-linux make 
PIN_ROOT=/home/user1/Tools/pin/pin-2.14-71313-gcc.4.4.7-linux make obj-intel64/ins_print.so

32bit cross-compile:

# Creates output dir
PIN_ROOT=/home/user1/Tools/pin/pin-2.14-71313-gcc.4.4.7-linux TARGET=ia32 make

# Perform compilation
PIN_ROOT=/home/user1/Tools/pin/pin-2.14-71313-gcc.4.4.7-linux TARGET=ia32 make obj-ia32/ins_print.so


# To run the tool
~/Tools/pin/pin-2.14-71313-gcc.4.4.7-linux/pin.sh -t obj-intel64/ins_print.so -- /bin/ls 


