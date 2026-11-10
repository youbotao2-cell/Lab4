`timescale 1ns/1ps

// Owner A. Default 1,000,000 samples at 50 MHz = 20 ms.
// A stable release is required after reset before accepting a new press.
module key_filter #(
    parameter integer DEBOUNCE_CYCLES = 1000000
) (
    input wire clk,
    input wire rst_n,
    input wire key_in,
    output reg key_db,
    output reg click
);
    localparam integer COUNT_W = (DEBOUNCE_CYCLES <= 1)
                                 ? 1 : $clog2(DEBOUNCE_CYCLES);
    localparam [COUNT_W-1:0] COUNT_LAST = DEBOUNCE_CYCLES - 1;
    (* async_reg = "true" *) reg key_meta;
    (* async_reg = "true" *) reg key_sync;
    reg [1:0] sync_ready;
    reg candidate;
    reg [COUNT_W-1:0] stable_count;
    reg armed;

    // Ordinary key edges are data, never clocks.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_meta <= 1'b1;
            key_sync <= 1'b1;
            sync_ready <= 2'b00;
        end else begin
            key_meta <= key_in;
            key_sync <= key_meta;
            sync_ready <= {sync_ready[0], 1'b1};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            candidate    <= 1'b1;
            stable_count <= {COUNT_W{1'b0}};
            key_db       <= 1'b1;
            click        <= 1'b0;
            armed        <= 1'b0;
        end else begin
            click <= 1'b0;
            if (!sync_ready[1]) begin
                stable_count <= {COUNT_W{1'b0}};
            end else if (key_sync != candidate) begin
                candidate    <= key_sync;
                stable_count <= {COUNT_W{1'b0}};
            end else if (stable_count == COUNT_LAST) begin
                key_db <= candidate;
                if (candidate) begin
                    armed <= 1'b1;
                end else if (armed) begin
                    click <= 1'b1;
                    armed <= 1'b0;
                end
            end else begin
                stable_count <= stable_count + 1'b1;
            end
        end
    end
endmodule
