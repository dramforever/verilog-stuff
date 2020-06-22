cmake_minimum_required(VERSION 3.17)

project(pipeline)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(absl REQUIRED)

add_executable(Vpipeline pipeline.cpp)
verilate(Vpipeline
    SOURCES pipeline.sv counter.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)

target_link_libraries(Vpipeline PRIVATE absl::strings absl::str_format)