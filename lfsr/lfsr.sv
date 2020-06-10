`default_nettype none

module lfsr (
    input logic clk,
    input logic rst,
    input logic in,
    output logic out_gal,
    output logic out_fib
);

    localparam INIT     = 8'b1000_0000;
    localparam FIB_TAP  = 8'b0010_1101;
    localparam GAL_TAP  = 8'b1011_0100;

    logic [7:0] gal_state, fib_state;
    initial gal_state = INIT;
    initial fib_state = INIT;

    always @(posedge clk)
        if (rst) begin
            gal_state <= INIT;
            fib_state <= INIT;
        end else begin
            if (gal_state[0])
                gal_state <= { in, gal_state[7:1] } ^ GAL_TAP;
            else
                gal_state <= { in, gal_state[7:1] };

            fib_state <= { ^(fib_state & FIB_TAP) ^ in, fib_state[7:1] };
        end

    assign out_gal = gal_state[0];
    assign out_fib = fib_state[0];

`ifdef FORMAL
    always @(*)
        assert(out_gal == out_fib);
`endif
endmodule
