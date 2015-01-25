all: check-env default

ifeq (exists, $(shell [ -e Make.user ] && echo exists ))
include Make.user 
endif

.PHONY: all clean check-env default

check-env:
ifndef LLVM_CONFIG
	$(error Please set environment variable LLVM_CONFIG)
endif

CXX = g++
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC 
CXXFLAGS = -g

INC += -I$(shell $(LLVM_CONFIG) --includedir)
LLVM_LIB = $(shell $(LLVM_CONFIG) --libdir)
LLVM_SRC = $(shell $(LLVM_CONFIG) --src-root)
LIBS = -L$(LLVM_LIB)

ifdef USE_CLANG_CPP
  INC += -I"$(LLVM_SRC)/tools/clang/tools/libclang"
  LIBS += -Wl,--whole-archive					\
          $(addprefix $(LLVM_LIB)/,$(shell $(LLVM_CONFIG) --libnames))	\
          -Wl,--no-whole-archive
  CXXFLAGS += -DUSE_CLANG_CPP
endif

OBJS = wrapclang.cpp.o
LIBS += -lclang

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

%.c.o: %.c %.h
	$(CC) $< -fPIC -c -o $@ $(INC) $(CFLAGS) $(FLAGS)

%.cpp.o: %.cpp %.h
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) $(FLAGS)

libwrapclang.$(SHLIB_EXT): $(OBJS)
	$(CXX) $(OBJS) -rdynamic -shared -o $@ -L$(LLVM_LIB) $(LDFLAGS) $(LIBS)

clean:
	rm -f *.o *.$(SHLIB_EXT)
