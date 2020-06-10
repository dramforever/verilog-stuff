`default_nettype none

module walker #(
    CLOCK_FREQ = 32'd1_000_0000
) (
    input logic i_clk,
    input logic i_rst,
    output logic [7:0] o_leds
);
    logic stb;

    counter #(
        .PERIOD(CLOCK_FREQ)
    ) counter_0 (
        .i_clk, .i_rst,
        .o_overflow(stb)
    );

    logic [3:0] state;
    initial state = 4'd0;

    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= 4'd0;
        end else begin
            if (stb) begin
                case (state)
                    4'd13:   state <= 4'd0;
                    default: state <= state + 1'b1;
                endcase
            end
        end
    end

    always @(*) begin
        case (state)
            4'd0:    o_leds = 8'b0000_0001;
            4'd1:    o_leds = 8'b0000_0010;
            4'd2:    o_leds = 8'b0000_0100;
            4'd3:    o_leds = 8'b0000_1000;
            4'd4:    o_leds = 8'b0001_0000;
            4'd5:    o_leds = 8'b0010_0000;
            4'd6:    o_leds = 8'b0100_0000;
            4'd7:    o_leds = 8'b1000_0000;
            4'd8:    o_leds = 8'b0100_0000;
            4'd9:    o_leds = 8'b0010_0000;
            4'd10:   o_leds = 8'b0001_0000;
            4'd11:   o_leds = 8'b0000_1000;
            4'd12:   o_leds = 8'b0000_0100;
            4'd13:   o_leds = 8'b0000_0010;
            default: o_leds = 8'b0000_0000;
        endcase
    end

`ifdef FORMAL
    always @(posedge i_clk)
        assert (state <= 4'd13);

    logic past_valid;
    initial past_valid = 1'b0;
    always @(posedge i_clk)
        past_valid <= ~ i_rst;

    always @(posedge i_clk)
        if (past_valid && $fell(stb))
            assert ((o_leds & $past(o_leds)) == 8'b0);
`endif
endmodule
