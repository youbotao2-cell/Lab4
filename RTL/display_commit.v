`timescale 1ns/1ps
`include "lab4_defs.vh"

// Owner B. Keep the displayed selection stable throughout active video.
module display_commit (
    input wire clk,
    input wire rst_n,
    input wire blank_start,
    input wire [1:0] ctrl_state,
    output reg [1:0] display_state
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_state <= `SCREEN_BAR;
        else if (blank_start)
            display_state <= ctrl_state;
    end
endmodule
