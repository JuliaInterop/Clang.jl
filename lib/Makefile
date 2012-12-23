JULIAHOME=/cmn/git/julia
include $(JULIAHOME)/Make.inc

CC=g++

clangpath=/usr/include/clang-c
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC\
	-I$(JULIAHOME)/src -I$(JULIAHOME)/src/support -I$(USR)/include -L$(JULIAHOME)/usr/lib
INC=-I/cmn/git/julia/deps/llvm-3.1/tools/clang/include/clang-c

all:
	$(CC) wrapcindex.cpp -shared -o libwrapcindex.so $(INC) -L$(USRLIB) $(FLAGS) -ljulia-release -lev -lclang -g
