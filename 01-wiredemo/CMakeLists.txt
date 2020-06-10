cmake_minimum_required(VERSION 3.17)

project(wiredemo)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(Vwiredemo wiredemo.cpp)
verilate(Vwiredemo
    SOURCES wiredemo.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst)
