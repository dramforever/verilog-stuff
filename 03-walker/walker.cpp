#include <memory>
#include <utility>
#include <random>
#include <iostream>
#include <chrono>

#include "absl/strings/str_format.h"

#include "Vwalker.h"
#include "verilated_fst_c.h"

using std::chrono::nanoseconds;

template<typename Rep, typename Period>
nanoseconds::rep to_ns(
    std::chrono::duration<Rep, Period> dur
) {
    return std::chrono::duration_cast<nanoseconds>(dur).count();
}

template<typename Module>
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

        module->i_clk = 0;
        module->eval();
        if (trace)
            trace->dump(period * m_counter + period / 2);

        module->i_clk = 1;
        module->eval();
        m_counter ++;
        if (trace)
            trace->dump(period * m_counter);
    }

    void reset() {
        module->i_rst = 1;
        tick();
        module->i_rst = 0;
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
    DUT<Vwalker> dut(clock_period);

    Verilated::mkdir("simout");
    dut.open_trace("simout/dump.fst");

    dut.reset();
    int last_leds = 0;

    while (! Verilated::gotFinish()) {
        dut.tick();

        if (dut->o_leds != last_leds) {
            last_leds = dut->o_leds;

            std::cout << absl::StreamFormat(
                "[%9d] %02x\n",
                dut.counter(),
                last_leds
            );
        }

        if (dut.time() > 20s) {
            break;
        }
    }
}
