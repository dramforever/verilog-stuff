cmake_minimum_required(VERSION 3.17)

project(walker)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(absl REQUIRED)

add_executable(Vwalker walker.cpp)
verilate(Vwalker
    SOURCES walker.sv counter.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)

target_link_libraries(Vwalker PUBLIC absl::strings absl::str_format)