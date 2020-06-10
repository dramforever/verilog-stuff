cmake_minimum_required(VERSION 3.17)

project(lfsr)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(Vlfsr lfsr.cpp)
verilate(Vlfsr
    SOURCES lfsr.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst)
