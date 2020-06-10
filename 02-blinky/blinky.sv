`default_nettype none

module blinky #(
    parameter CLOCK_FREQ = 32'd1_000_000
) (
    input logic i_clk,
    input logic i_rst,
    output logic o_led
);
    logic stb;

    counter #(
        .PERIOD(CLOCK_FREQ)
    ) counter_0 (
        .i_clk, .i_rst,
        .o_overflow(stb)
    );

    always_ff @(posedge i_clk)
        if (i_rst) begin
            o_led <= '0;
        end else if (stb) begin
            o_led <= ~ o_led;
        end
endmodule
