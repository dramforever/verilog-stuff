#include <memory>
#include <utility>
#include <random>
#include <iostream>
#include <chrono>
#include <cctype>

#include "absl/strings/str_format.h"

#include "Vserialtx.h"
#include "verilated_fst_c.h"

using std::chrono::nanoseconds;
using namespace std::chrono_literals;

using Module = Vserialtx;

template<typename Rep, typename Period>
nanoseconds::rep to_ns(
    std::chrono::duration<Rep, Period> dur
) {
    return std::chrono::duration_cast<nanoseconds>(dur).count();
}

class UARTReader {
private:
    nanoseconds sample_period, sample_period_longer;
    nanoseconds next_sample;
    uint8_t buffer;
    size_t index;
    bool reading;

public:
    UARTReader(nanoseconds sample_period):
        sample_period(sample_period),
        sample_period_longer(sample_period + sample_period / 2),
        reading(false) {
    }

    void process_sample(nanoseconds time, CData data) {
        if (! reading && ! data) {
            reading = true;
            index = 0;
            buffer = 0;
            next_sample = time + sample_period_longer;
        } else {
            if (reading && next_sample <= time) {
                if (index < CHAR_BIT) {
                    if (data) buffer |= (1 << index);
                    index ++;
                } else if (index == CHAR_BIT) {
                    if (data) {
                        if (isprint(buffer))
                            std::cout << absl::StreamFormat(
                                "[%9d] UART: 0x%02x [%c]\n",
                                to_ns(time),
                                int(buffer),
                                char(buffer)
                            );
                        else
                            std::cout << absl::StreamFormat(
                                "[%9d] UART: 0x%02x\n",
                                to_ns(time),
                                int(buffer)
                            );
                    } else {
                        std::cout << absl::StreamFormat(
                            "[%9d] UART: framing error %02x\n",
                            to_ns(time),
                            int(buffer)
                        );
                    }
                    reading = false;
                }

                next_sample += sample_period;
            }
        }
    }
};

class DUT {
private:
    std::unique_ptr<Module> module;
    std::unique_ptr<VerilatedFstC> trace;
    nanoseconds clock_period;
    vluint64_t m_counter;
    UARTReader uart;

public:
    DUT(nanoseconds clock_period):
        module(std::make_unique<Module>()),
        trace(),
        clock_period(clock_period),
        m_counter(0),
        uart(nanoseconds(1s) / 115200) {
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

        uart.process_sample(time(), module->uart_tx);
    }

    void reset() {
        module->rst = 1;
        tick();
        module->rst = 0;
    }

    uint32_t wb_read(uint32_t addr) {
        vluint64_t stall_clk = 0, wait_clk = 0;

        module->wb_cyc = 1;
        module->wb_stb = 1;
        module->wb_addr = addr;
        module->eval(); // wb_stall may be non-registered
        while (module->wb_stall) {
            stall_clk ++;
            tick();
        }
        tick();
        module->wb_stb = 0;
        while (! module->wb_ack) {
            wait_clk ++;
            tick();
        }
        uint32_t res = module->wb_data_r;
        module->wb_cyc = 0;

        return res;
    }

    void wb_write(uint32_t addr, uint32_t val) {
        vluint64_t stall_clk = 0, wait_clk = 0;

        module->wb_cyc = 1;
        module->wb_stb = 1;
        module->wb_we = 1;
        module->wb_addr = addr;
        module->wb_data_w = val;
        module->eval(); // wb_stall may be non-registered
        while (module->wb_stall) {
            stall_clk ++;
            tick();
        }
        tick();
        module->wb_stb = 0;
        while (! module->wb_ack) {
            wait_clk ++;
            tick();
        }
        module->wb_cyc = 0;
        module->wb_we = 0;

        std::cout << absl::StreamFormat("[%9d] wb_write(0x%x, 0x%x): stall=%d wait=%d\n",
            to_ns(time()),
            addr, val,
            stall_clk, wait_clk
        );
    }

    virtual ~DUT() {
        module->final();
    }

    Module* operator->() {
        return module.get();
    }
};

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);

    auto clock_period = nanoseconds(1s) / 100'000'000;
    DUT dut(clock_period);

    Verilated::mkdir("simout");
    dut.open_trace("simout/dump.fst");

    dut.reset();
    int last_leds = 0;

    std::random_device rd;
    std::mt19937 rng(rd());
    std::uniform_int_distribution<size_t> dist(256);

    for (char c : { 'H', 'e', 'l', 'l', 'o' }) {
        std::cout << absl::StreamFormat(
            "[%9d] Sending %c\n",
            to_ns(dut.time()),
            c
        );
        dut.wb_write(0, c);
    }

    std::cout << absl::StreamFormat("Current: %d bytes sent\n", dut.wb_read(0));

    while (dut.wb_read(0) < 5);

    std::cout << absl::StreamFormat("Done, %d bytes sent", dut.wb_read(0));
}
