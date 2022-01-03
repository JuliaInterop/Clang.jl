cmake_minimum_required(VERSION 3.12)
project(bitfield)

add_library(bitfield SHARED ${PROJECT_SOURCE_DIR}/bitfield.c)
target_include_directories(bitfield PRIVATE ${PROJECT_SOURCE_DIR})
set_property(TARGET bitfield PROPERTY WINDOWS_EXPORT_ALL_SYMBOLS ON)

install(FILES ${PROJECT_SOURCE_DIR}/bitfield.h DESTINATION include)
install(TARGETS bitfield DESTINATION bin)
