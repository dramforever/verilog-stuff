`default_nettype none

module wiredemo (
    i_sw,
    o_led
);
    input logic i_sw;
    output logic o_led;

    assign o_led = i_sw;
endmodule
