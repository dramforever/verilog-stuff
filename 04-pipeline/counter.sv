`default_nettype none

module counter #(
    parameter PERIOD = 1000
) (
    input logic clk,
    input logic rst,
    input logic clear,
    output logic overflow
);
    localparam WIDTH = $clog2(PERIOD);

    logic [WIDTH - 1 : 0] ctr;
    initial ctr = 0;

    logic [WIDTH - 1 : 0] next_ctr;
    assign next_ctr = ctr + 1'b1;

    logic overflow_;
    assign overflow_ = next_ctr == PERIOD[WIDTH - 1 : 0];
    assign overflow = overflow_;

    always @(posedge clk)
        if (rst || overflow_) begin
            ctr <= 0;
        end else if (clear) begin
            ctr <= 1;
        end else begin
            ctr <= next_ctr;
        end
endmodule
