cmake_minimum_required(VERSION 3.17)

project(lfsr)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(absl REQUIRED)

add_executable(Vlfsr lfsr.cpp)
verilate(Vlfsr
    SOURCES lfsr.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst)

target_link_libraries(Vlfsr PRIVATE absl::strings absl::str_format)