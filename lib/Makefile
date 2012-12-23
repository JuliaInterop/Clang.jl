all: check-env default

.PHONY: check-env

check-env:
ifndef JULIAHOME
	$(error Environment variable JULIAHOME is not set.)
endif

CC=g++
INC=-I$(JULIAHOME)/deps/llvm-3.1/tools/clang/include/clang-c
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC\
	-I$(JULIAHOME)/src -I$(JULIAHOME)/src/support -I$(USR)/include -L$(JULIAHOME)/usr/lib

default:
	$(CC) wrapcindex.cpp -shared -o libwrapcindex.so $(INC) -L$(USRLIB) $(FLAGS) -ljulia-release -lev -lclang -g
