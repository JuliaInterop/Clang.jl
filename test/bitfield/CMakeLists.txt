cmake_minimum_required(VERSION 3.12)
project(bitfield)

add_library(bitfield SHARED ${PROJECT_SOURCE_DIR}/bitfield.c)
target_include_directories(bitfield PRIVATE ${PROJECT_SOURCE_DIR})

install(FILES ${PROJECT_SOURCE_DIR}/bitfield.h DESTINATION include)
install(TARGETS bitfield DESTINATION bin)
