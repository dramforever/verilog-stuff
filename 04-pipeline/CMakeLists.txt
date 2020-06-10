cmake_minimum_required(VERSION 3.17)

project(pipeline)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
add_executable(Vpipeline pipeline.cpp)
verilate(Vpipeline
    SOURCES pipeline.sv counter.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)
