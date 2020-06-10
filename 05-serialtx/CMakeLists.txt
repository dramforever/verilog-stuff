cmake_minimum_required(VERSION 3.17)

project(serialtx)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(Vserialtx serialtx.cpp)
verilate(Vserialtx
    SOURCES serialtx.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)
