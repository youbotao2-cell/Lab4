`timescale 1ns/1ps

module screen_fsm (
    input wire clk,
    input wire rst_n,
    input wire click,
    output reg [1:0] ctrl_state
);
    localparam [1:0] SCREEN_BAR = 2'd0;
    localparam [1:0] SCREEN_MUST = 2'd1;
    localparam [1:0] SCREEN_END = 2'd2;

    reg [1:0] next_state;
    always @(*) begin
        next_state = ctrl_state;
        case (ctrl_state)
            SCREEN_BAR:  if (click) next_state = SCREEN_MUST;
            SCREEN_MUST: if (click) next_state = SCREEN_END;
            SCREEN_END:  if (click) next_state = SCREEN_BAR;
            default: next_state = SCREEN_BAR;
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ctrl_state <= SCREEN_BAR;
        else
            ctrl_state <= next_state;
    end
endmodule
