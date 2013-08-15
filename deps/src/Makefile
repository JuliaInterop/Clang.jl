all: check-env default

.PHONY: all clean check-env default

check-env:
ifndef JULIA_ROOT
	$(error Environment variable JULIA_ROOT is not set.)
endif

CXX = g++
INC = -I"$(JULIA_ROOT)/usr/include"
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC
CXXFLAGS = -g
OBJS = wrapclang.cpp.o
LIBS = -lclang

ifdef USE_CLANG_CPP
	INC += -I"$(JULIA_ROOT)/deps/llvm-3.3/tools/clang/tools/libclang"
	LIBS += -lclangAST
	CXXFLAGS += -DUSE_CLANG_CPP
endif

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
	$(CXX) $(OBJS) -rdynamic -shared -o $@ -L"$(JULIA_ROOT)/usr/lib" $(LDFLAGS) $(LIBS)

clean:
	rm -f *.o *.$(SHLIB_EXT)
