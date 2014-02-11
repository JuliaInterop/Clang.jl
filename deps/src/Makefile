all: check-env default

ifeq (exists, $(shell [ -e Make.user ] && echo exists ))
include Make.user 
endif

.PHONY: all clean check-env default

check-env:
ifndef JULIA_ROOT
  $(error Environment variable JULIA_ROOT is not set.)
endif

CXX = g++
INC =
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC 
CXXFLAGS = -g
LIBS =
LIB_DIR =
LLVM_VER = 3.3

ifdef LLVM_CONFIG
  INC += -I$(shell $(LLVM_CONFIG) --includedir)
  LIB_DIR += -L$(shell $(LLVM_CONFIG) --libdir)
else
  INC += -I"$(JULIA_ROOT)/usr/include"
  LIB_DIR += -L"$(JULIA_ROOT)/usr/lib"
endif

ifdef USE_CLANG_CPP
  JLIB = "$(JULIA_ROOT)/usr/lib"
  INC += -I"$(JULIA_ROOT)/deps/llvm-$(LLVM_VER)/tools/clang/tools/libclang"
  LIBS += -Wl,--whole-archive -Wl,--whole-archive \
          "$(JLIB)/libclang.a" "$(JLIB)/libclangAST.a" "$(JLIB)/libclangAnalysis.a" \
          "$(JLIB)/libclangARCMigrate.a" "$(JLIB)/libclangASTMatchers.a" "$(JLIB)/libclangBasic.a" \
          "$(JLIB)/libclangCodeGen.a" "$(JLIB)/libclangDriver.a" "$(JLIB)/libclangEdit.a" \
          "$(JLIB)/libclangFormat.a" "$(JLIB)/libclangFrontend.a" "$(JLIB)/libclangFrontendTool.a" \
          "$(JLIB)/libclangLex.a" "$(JLIB)/libclangParse.a" "$(JLIB)/libclangRewriteCore.a" \
          "$(JLIB)/libclangRewriteFrontend.a" "$(JLIB)/libclangSema.a" \
          "$(JLIB)/libclangSerialization.a" "$(JLIB)/libclangStaticAnalyzerCore.a" \
          "$(JLIB)/libclangStaticAnalyzerFrontend.a" "$(JLIB)/libclangTooling.a" \
          -Wl,--no-whole-archive -l"LLVM-$(LLVM_VER)"
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

%.c.o: %.c
	$(CC) $< -fPIC -c -o $@ $(INC) $(CFLAGS) $(FLAGS)

%.cpp.o: %.cpp
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) $(FLAGS)

libwrapclang.$(SHLIB_EXT): $(OBJS)
	$(CXX) $(OBJS) -rdynamic -shared -o $@ $(LIB_DIR) $(LDFLAGS) $(LIBS)

clean:
	rm -f *.o *.$(SHLIB_EXT)
