cmake_minimum_required(VERSION 3.17)

project(walker)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(Vwalker walker.cpp)
verilate(Vwalker
    SOURCES walker.sv counter.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)
