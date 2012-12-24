all: check-env default
include $(JULIAHOME)/Make.inc

.PHONY: all clean check-env default

check-env:
ifndef JULIAHOME
	$(error Environment variable JULIAHOME is not set.)
endif

CXX = g++
INC = -I"$(JULIAHOME)/deps/llvm-3.1/tools/clang/include/clang-c"

OBJS = wrapcindex.o

default: libwrapcindex.$(SHLIB_EXT)

%.o: %.cpp
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) -g

libwrapcindex.$(SHLIB_EXT): $(OBJS)
	$(CXX) $(OBJS) -shared -o $@ -L"$(JULIAHOME)/usr/lib" $(LDFLAGS) $(LIBS) -lclang

clean:
	rm -f *.o *.$(SHLIB_EXT)
