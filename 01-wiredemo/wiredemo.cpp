#include <memory>
#include <utility>
#include <random>
#include <iostream>

#include "absl/strings/str_format.h"

#include "Vwiredemo.h"
#include "verilated_fst_c.h"

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Verilated::mkdir("simout");

    auto dut = std::make_unique<Vwiredemo>();
    auto trace = std::make_unique<VerilatedFstC>();
    dut->trace(trace.get(), 0);
    trace->open("simout/dump.fst");

    std::random_device rd;
    std::mt19937 rng(rd());
    std::uniform_int_distribution<CData> dist(0, 1);

    vluint64_t counter = 0;
    while (! Verilated::gotFinish()) {
        auto value = dist(rng);
        dut->i_sw = value;
        dut->eval();
        trace->dump(10 * counter);

        if (counter ++ > 1'000'000LLU) {
            break;
        }
    }

    dut->final();
}
