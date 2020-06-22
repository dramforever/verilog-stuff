cmake_minimum_required(VERSION 3.17)

project(blinky)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
find_package(absl REQUIRED)

add_executable(Vblinky blinky.cpp)
verilate(Vblinky
    SOURCES blinky.sv
    VERILATOR_ARGS -Wall -O3 --trace-fst -f input.vc)

target_link_libraries(Vblinky PUBLIC absl::strings absl::str_format)