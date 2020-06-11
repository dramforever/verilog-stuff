`default_nettype none

module serialtx #(
    // DIVIDE = 868, // 115200 baud with 100MHz clock
    DIVIDE = 2, // For easier testing

    FRAME = 8
) (
    input logic clk,
    input logic rst,
    output logic uart_tx,

    // Wishbone
    /* verilator lint_off UNUSED */
    input logic [31:0] wb_addr,
    input logic [FRAME - 1 : 0] wb_data_w,
    output logic [31:0] wb_data_r,
    input logic wb_we, wb_stb, wb_cyc,
    output logic wb_ack, wb_stall
    /* verilator lint_on UNUSED */
);
    localparam STATE_WIDTH = $clog2(FRAME + 3);
    logic [STATE_WIDTH - 1 : 0] state;
    initial state = 0;

    logic busy;
    assign busy = state != 0;

    assign wb_stall = busy && wb_cyc;

    initial wb_ack = 1'b0;
    always @(posedge clk) begin
        if (rst) begin
            wb_ack <= 1'b0;
        end else begin
            wb_ack <= wb_stb && ! busy;
        end
    end

    logic [31:0] num_bytes;
    initial num_bytes = 0;

    assign wb_data_r = num_bytes;

    logic [FRAME - 1 : 0] data;

    localparam DIV_WIDTH = $clog2(DIVIDE);
    logic [DIV_WIDTH - 1 : 0] div_counter;
    initial div_counter = 0;

    logic div_overflow;
    assign div_overflow = div_counter + 1'b1 == DIVIDE[DIV_WIDTH - 1 : 0];

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            div_counter <= 0;
            num_bytes <= 0;
        end else if (wb_cyc && ! busy && wb_stb && wb_we) begin
            state <= 1;
            data <= wb_data_w;
        end else if (state != 0) begin
            if (div_overflow) begin
                if (state == 1) begin
                    state <= 3;
                end else if (state == FRAME + 2) begin
                    state <= 2;
                end else if (state == 2) begin
                    state <= 0;
                    num_bytes <= num_bytes + 32'd1;
                end else begin
                    state <= state + 1'd1;
                end

                div_counter <= 0;
            end else begin
                div_counter <= div_counter + 1'd1;
            end
        end
    end

    always @(*)
        if (state == 1) begin
            uart_tx = 1'b0;
        end else if (state == 0 || state == 2) begin
            uart_tx = 1'b1;
        end else begin
            uart_tx = data[state - 3];
        end

`ifdef FORMAL
    initial assume(rst);

    logic past_valid;
    initial past_valid = 1'b0;
    always @(posedge clk)
        past_valid <= ~ rst;

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

    always @(*)
        if (state == 0)
            assert(uart_tx);
`endif
endmodule
