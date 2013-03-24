all: check-env default

.PHONY: all clean check-env default

check-env:
ifndef JULIAHOME
	$(error Environment variable JULIAHOME is not set.)
endif

CXX = g++
INC = -I"$(JULIAHOME)/usr/include" -I"$(JULIAHOME)/deps/llvm-3.2/tools/clang/tools/libclang" 
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC
CXXFLAGS = -g
OBJS = wrapclang.cpp.o

# Figure out OS and architecture
OS = $(shell uname)
ifeq ($(OS), MINGW32_NT-6.1)
  OS=WINNT
endif

# file extensions
ifeq ($(OS), WINNT)
  SHLIB_EXT = dll 
else ifeq ($(OS), Darwin)
  SHLIB_EXT = dylib
else
  SHLIB_EXT = so
endif

default: libwrapclang.$(SHLIB_EXT)

%.c.o: %.c
	$(CC) $< -fPIC -c -o $@ $(INC) $(CFLAGS) $(FLAGS)

%.cpp.o: %.cpp
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) $(FLAGS)

libwrapclang.$(SHLIB_EXT): $(OBJS)
	$(CXX) $(OBJS) -rdynamic -shared -o $@ -L"$(JULIAHOME)/usr/lib" $(LDFLAGS) $(LIBS) -lclang -lclangAST

clean:
	rm -f *.o *.$(SHLIB_EXT)
