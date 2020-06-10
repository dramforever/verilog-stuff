`default_nettype none

module counter #(
    parameter PERIOD
) (
    input logic i_clk,
    input logic i_rst,
    output logic o_overflow
);
    localparam WIDTH = $clog2(PERIOD);

    reg [WIDTH - 1 : 0] ctr;
    initial ctr = 0;

    logic [WIDTH - 1 : 0] next_ctr;
    assign next_ctr = ctr + 1'b1;

    logic overflow;
    assign overflow = next_ctr == PERIOD[WIDTH - 1 : 0];
    assign o_overflow = overflow;

    always @(posedge i_clk)
        if (i_rst || overflow) begin
            ctr <= 0;
        end else begin
            ctr <= next_ctr;
        end
endmodule
