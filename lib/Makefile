all: check-env default

.PHONY: all clean check-env default

check-env:
ifndef JULIAHOME
	$(error Environment variable JULIAHOME is not set.)
endif

CXX=g++
INC=-I"$(JULIAHOME)/deps/llvm-3.1/tools/clang/include/clang-c"
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC\
	-I"$(JULIAHOME)/src" -I"$(JULIAHOME)/src/support" -I"$(USR)/include"

OBJS = wrapcindex.o

default: libwrapcindex.$(SHLIB_EXT)

%.o: %.c
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) $(FLAGS) -g

libwrapcindex.$(SHLIB_EXT): $(OBJS)
       $(CXX) $(OBJS) -shared -o $@ -L"$(USRLIB)" -L"$(JULIAHOME)/usr/lib" $(LDFLAGS) -lclang $(LIBS)

clean:
       rm -f *.o *.$(SHLIB_EXT)
