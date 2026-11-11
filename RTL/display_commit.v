`timescale 1ns/1ps

module display_commit (
    input wire clk,
    input wire rst_n,
    input wire blank_start,
    input wire [1:0] ctrl_state,
    output reg [1:0] display_state
);
    localparam [1:0] SCREEN_BAR = 2'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_state <= SCREEN_BAR;
        else if (blank_start)
            display_state <= ctrl_state;
    end
endmodule
