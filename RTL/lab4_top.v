`timescale 1ns/1ps

module lab4_top (
    input wire sys_clk,
    input wire sys_rst_n,
    input wire key_in,
    output wire hsync,
    output wire vsync,
    output wire [15:0] rgb
);
    parameter integer DEBOUNCE_CYCLES = 1000000;
    parameter SYNC_ACTIVE_HIGH = 1'b1;

    wire key_db;
    wire click;
    wire [1:0] ctrl_state;
    wire [1:0] display_state;
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire active_video;
    wire blank_start;
    wire [15:0] pix_data;
    wire ctrl_rst_n;
    reset_sync u_reset (
        .clk(sys_clk), .async_rst_n(sys_rst_n), .rst_n(ctrl_rst_n)
    );
    key_filter #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_key (
        .clk(sys_clk), .rst_n(ctrl_rst_n), .key_in(key_in),
        .key_db(key_db), .click(click)
    );
    screen_fsm u_fsm (
        .clk(sys_clk), .rst_n(ctrl_rst_n), .click(click), .ctrl_state(ctrl_state)
    );
    display_commit u_display (
        .clk(sys_clk), .rst_n(ctrl_rst_n), .blank_start(blank_start),
        .ctrl_state(ctrl_state), .display_state(display_state)
    );
    vga_timing #(.SYNC_ACTIVE_HIGH(SYNC_ACTIVE_HIGH)) u_timing (
        .clk(sys_clk), .pix_x(pix_x), .pix_y(pix_y),
        .active_video(active_video), .blank_start(blank_start),
        .hsync(hsync), .vsync(vsync)
    );
    screen_pixels u_pixels (
        .pix_x(pix_x), .pix_y(pix_y),
        .display_state(display_state), .pix_data(pix_data)
    );
    assign rgb = active_video ? pix_data : 16'h0000;
endmodule
