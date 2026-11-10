`timescale 1ns/1ps

// Asynchronous assertion, two-clock synchronous release in the control domain.
module reset_sync (
    input wire clk,
    input wire async_rst_n,
    output wire rst_n
);
    (* async_reg = "true" *) reg [1:0] release_pipe;
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            release_pipe <= 2'b00;
        else
            release_pipe <= {release_pipe[0], 1'b1};
    end
    assign rst_n = release_pipe[1];
endmodule
