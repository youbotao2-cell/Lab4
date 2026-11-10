`timescale 1ns/1ps

// Owner C. Fixed 640x480 visible area, 800x525 complete raster.
// Pixel stepping uses a 25 MHz enable inside the 50 MHz clock domain.
// User reset does not stop scanning: reset must still display color bars.
// TODO(board): verify synthesized register-initialization support, or replace
// initialization with a board-specific power-on reset independent of user reset.
module vga_timing #(
    parameter SYNC_ACTIVE_HIGH = 1'b1
) (
    input wire clk,
    output wire [9:0] pix_x,
    output wire [9:0] pix_y,
    output wire active_video,
    output wire blank_start,
    output wire hsync,
    output wire vsync
);
    localparam [9:0] H_TOTAL = 10'd800;
    localparam [9:0] V_TOTAL = 10'd525;
    localparam [9:0] H_BEGIN = 10'd144; // 96 + 40 + 8
    localparam [9:0] H_END   = 10'd784; // 144 + 640
    localparam [9:0] V_BEGIN = 10'd35;  // 2 + 25 + 8
    localparam [9:0] V_END   = 10'd515; // 35 + 480
    reg pixel_phase;
    reg [9:0] h_count;
    reg [9:0] v_count;
    initial begin
        pixel_phase = 1'b0;
        h_count = 10'd0;
        v_count = 10'd0;
    end
    always @(posedge clk) begin
        pixel_phase <= ~pixel_phase;
        if (pixel_phase) begin
            if (h_count == H_TOTAL - 1'b1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1'b1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end
    assign active_video = (h_count >= H_BEGIN) && (h_count < H_END) &&
                          (v_count >= V_BEGIN) && (v_count < V_END);
    assign pix_x = active_video ? h_count - H_BEGIN : 10'd0;
    assign pix_y = active_video ? v_count - V_BEGIN : 10'd0;
    // One system-clock pulse on entry to vertical blank after active row 479.
    assign blank_start = pixel_phase && (h_count == H_TOTAL - 1'b1) &&
                         (v_count == V_END - 1'b1);
    assign hsync = (h_count < 10'd96) ? SYNC_ACTIVE_HIGH : ~SYNC_ACTIVE_HIGH;
    assign vsync = (v_count < 10'd2) ? SYNC_ACTIVE_HIGH : ~SYNC_ACTIVE_HIGH;
endmodule
