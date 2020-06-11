`default_nettype none

module pipeline #(
    CLOCK_FREQ = 32'd1_000_0000
) (
    input logic clk,
    input logic rst,
    output logic [7:0] leds,

    // Wishbone
    /* verilator lint_off UNUSED */
    input logic [31:0] wb_addr,
    input logic [31:0] wb_data_w,
    output logic [31:0] wb_data_r,
    input logic wb_we, wb_stb, wb_cyc,
    output logic wb_ack, wb_stall
    /* verilator lint_on UNUSED */
);
    logic overflow;
    logic counter_clear;

    counter #(
        .PERIOD(2)
    ) counter_0 (
        .clk, .rst,
        .clear(counter_clear),
        .overflow
    );

    logic [3:0] state;
    initial state = 4'd0;

    logic busy;
    assign busy = state != 4'd0;

    assign wb_stall = busy && wb_cyc;

    initial wb_ack = 1'b0;
    always @(posedge clk) begin
        if (rst) begin
            wb_ack <= 1'b0;
        end else begin
            wb_ack <= wb_stb && ! busy;
        end
    end

    assign wb_data_r = { 28'b0, state };

    always @(posedge clk) begin
        if (rst) begin
            state <= 4'd0;
            counter_clear <= 1'b0;
        end else if (wb_cyc && ! busy && wb_stb && wb_we) begin
            state <= 4'd1;
            counter_clear <= 1'b1;
        end else begin
            if (overflow) begin
                case (state)
                4'd0:       state <= 4'd0;
                4'd14:      state <= 4'd0;
                default:    state <= state + 1'b1;
                endcase
            end
            counter_clear <= 1'b0;
        end
    end

    always @(*) begin
        case (state)
            4'd1:       leds = 8'b0000_0001;
            4'd2:       leds = 8'b0000_0010;
            4'd3:       leds = 8'b0000_0100;
            4'd4:       leds = 8'b0000_1000;
            4'd5:       leds = 8'b0001_0000;
            4'd6:       leds = 8'b0010_0000;
            4'd7:       leds = 8'b0100_0000;
            4'd8:       leds = 8'b1000_0000;
            4'd9:       leds = 8'b0100_0000;
            4'd10:      leds = 8'b0010_0000;
            4'd11:      leds = 8'b0001_0000;
            4'd12:      leds = 8'b0000_1000;
            4'd13:      leds = 8'b0000_0100;
            4'd14:      leds = 8'b0000_0010;
            default:    leds = 8'b0000_0000;
        endcase
    end

`ifdef FORMAL
    initial assume(rst);

    always @(*)
        assert(state <= 4'd14);

    always @(*)
        if (leds) assert(busy);

    logic past_valid;
    initial past_valid = 1'b0;
    always @(posedge clk)
        past_valid <= ~ rst;

    always @(posedge clk)
        if (past_valid && $fell(overflow))
            assert((leds & $past(leds)) == 8'b0);

    always @(posedge clk)
        if ($past(rst))
            assume(! wb_stb && ! wb_cyc);
    integer unfinished;
    initial unfinished = 0;

    always @(posedge clk)
        if (rst) begin
            unfinished <= 0;
        end else begin
            unfinished <= unfinished + (wb_stb && ! wb_stall) - wb_ack;
        end

    localparam MAX_TXN = 1;

    always @(*)
        assert(unfinished >= 0 && unfinished <= MAX_TXN);

    always @(*)
        if (unfinished > 0)
            assert(busy || wb_ack);

    always @(*)
        if(unfinished == MAX_TXN)
            assert((wb_stb && ! wb_stall) <= wb_ack);

    always @(*)
        if (busy)
            assert(unfinished == 0 || wb_ack);

    always @(*)
        if (wb_ack)
            assert(unfinished > 0);

    always @(*)
        if (unfinished > 0)
            assume(wb_cyc);

    always @(*)
        if (! wb_cyc) begin
            assume(! wb_stb && ! wb_we);
            assert(! wb_ack);
            assert(! wb_stall);
        end

    always @(posedge clk)
        if ($past(rst)) begin
            assert(! wb_ack);
            assert(! wb_stall);
        end
`endif
endmodule
