all: check-env default

.PHONY: all clean check-env default

check-env:
ifndef JULIAHOME
	$(error Environment variable JULIAHOME is not set.)
endif

CXX = g++
INC = -I"$(JULIAHOME)/usr/include/clang-c" \
      -I"$(JULIAHOME)/src" -I"$(JULIAHOME)/src/support" -I"$(JULIAHOME)/src/include"
FLAGS = -Wall -Wno-strict-aliasing -fno-omit-frame-pointer -fPIC
CXXFLAGS = -g
OBJS = wrapcindex.cpp.o

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

default: libwrapcindex.$(SHLIB_EXT)

%.c.o: %.c
	$(CC) $< -fPIC -c -o $@ $(INC) $(CFLAGS) $(FLAGS)

%.cpp.o: %.cpp
	$(CXX) $< -fPIC -c -o $@ $(INC) $(CXXFLAGS) $(FLAGS)

libwrapcindex.$(SHLIB_EXT): $(OBJS)
	$(CXX) $(OBJS) -shared -o $@ -L"$(JULIAHOME)/usr/lib" $(LDFLAGS) $(LIBS) -lclang

clean:
	rm -f *.o *.$(SHLIB_EXT)
