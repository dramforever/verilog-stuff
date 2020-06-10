#include <memory>
#include <utility>
#include <random>
#include <iostream>
#include <chrono>

#include <boost/format.hpp>

#include "Vpipeline.h"
#include "verilated_fst_c.h"

using std::chrono::nanoseconds;
using boost::format;

using Module = Vpipeline;

template<typename Rep, typename Period>
nanoseconds::rep to_ns(
    std::chrono::duration<Rep, Period> dur
) {
    return std::chrono::duration_cast<nanoseconds>(dur).count();
}

class DUT {
private:
    std::unique_ptr<Module> module;
    std::unique_ptr<VerilatedFstC> trace;
    nanoseconds clock_period;
    vluint64_t m_counter;

public:
    DUT(nanoseconds clock_period):
        module(std::make_unique<Module>()),
        trace(),
        clock_period(clock_period),
        m_counter(0) {
    }

    vluint64_t counter() {
        return m_counter;
    }

    nanoseconds time() {
        return clock_period * counter();
    }

    void open_trace(const char *filename) {
        Verilated::traceEverOn(true);
        trace = std::make_unique<VerilatedFstC>();
        module->trace(trace.get(), 0);
        trace->open(filename);
    }

    void tick() {
        const auto period = to_ns(clock_period);

        module->clk = 0;
        module->eval();
        if (trace)
            trace->dump(period * m_counter + period / 2);

        module->clk = 1;
        module->eval();
        m_counter ++;
        if (trace)
            trace->dump(period * m_counter);
    }

    void reset() {
        module->rst = 1;
        tick();
        module->rst = 0;
    }

    uint32_t wb_read(uint32_t addr) {
        module->wb_cyc = 1;
        module->wb_stb = 1;
        module->wb_addr = addr;
        module->eval(); // wb_stall may be non-registered
        while (module->wb_stall) tick();
        tick();
        module->wb_stb = 0;
        while (! module->wb_ack) tick();
        uint32_t res = module->wb_data_r;
        module->wb_cyc = 0;
        return res;
    }

    void wb_write(uint32_t addr, uint32_t val) {
        int n_stall = 0, n_wait = 0;
        module->wb_cyc = 1;
        module->wb_stb = 1;
        module->wb_we = 1;
        module->wb_addr = addr;
        module->wb_data_w = val;
        module->eval(); // wb_stall may be non-registered
        while (module->wb_stall) tick(), n_stall ++;
        tick();
        module->wb_stb = 0;
        while (! module->wb_ack) tick(), n_wait ++;
        module->wb_cyc = 0;
        module->wb_we = 0;
        std::cout << format("write stall=%1% wait=%2%\n") % n_stall % n_wait;
    }

    virtual ~DUT() {
        module->final();
    }

    Module* operator->() {
        return module.get();
    }
};

int main(int argc, char *argv[]) {
    using namespace std::chrono_literals;

    Verilated::commandArgs(argc, argv);

    auto clock_period = 1ms;
    DUT dut(clock_period);

    Verilated::mkdir("simout");
    dut.open_trace("simout/dump.fst");

    dut.reset();
    int last_leds = 0;

    std::random_device rd;
    std::mt19937 rng(rd());
    std::uniform_int_distribution<size_t> dist(13'000, 15'000);

    for (size_t i = 0; i < 10; i ++) {
        std::cout << format("Request %1%\n") % i;
        size_t wait = dist(rng);
        for (size_t j = 0; j < wait; j ++)
            dut.tick();
        dut.wb_write(0, 0);
    }
}
