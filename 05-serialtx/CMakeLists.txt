cmake_minimum_required(VERSION 3.17)

project(serialtx)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(absl REQUIRED)

add_executable(Vserialtx serialtx.cpp)
verilate(Vserialtx
    SOURCES serialtx.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)

target_link_libraries(Vserialtx PRIVATE absl::strings absl::str_format)