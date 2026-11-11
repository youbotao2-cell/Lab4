`timescale 1ns/1ps

module screen_pixels (
    input wire [9:0] pix_x,
    input wire [9:0] pix_y,
    input wire [1:0] display_state,
    output reg [15:0] pix_data
);
    localparam [1:0] SCREEN_BAR = 2'd0;
    localparam [1:0] SCREEN_MUST = 2'd1;
    localparam [1:0] SCREEN_END = 2'd2;

    reg char_valid;
    reg [2:0] glyph;
    reg [9:0] char_begin;
    reg [9:0] local_x;
    reg [9:0] local_y;
    reg [7:0] row_bits;

    function [7:0] glyph_row;
        input [2:0] glyph_id;
        input [2:0] row;
        reg [63:0] bitmap;
        begin
            // M/U/S/T reused from workspace RTL/vga_pic.v; E/N/D are new.
            case (glyph_id)
                3'd0: bitmap = 64'hC3E7FFDBC3C3C3C3;
                3'd1: bitmap = 64'hC3C3C3C3C3C3E73C;
                3'd2: bitmap = 64'h7EC3C07E0303C37E;
                3'd3: bitmap = 64'hFF18181818181818;
                3'd4: bitmap = 64'hFFC0C0FCC0C0C0FF;
                3'd5: bitmap = 64'hC3E3F3DBCFC7C3C3;
                3'd6: bitmap = 64'hFCC6C3C3C3C3C6FC;
                default: bitmap = 64'd0;
            endcase
            case (row)
                3'd0: glyph_row = bitmap[63:56];
                3'd1: glyph_row = bitmap[55:48];
                3'd2: glyph_row = bitmap[47:40];
                3'd3: glyph_row = bitmap[39:32];
                3'd4: glyph_row = bitmap[31:24];
                3'd5: glyph_row = bitmap[23:16];
                3'd6: glyph_row = bitmap[15:8];
                3'd7: glyph_row = bitmap[7:0];
                default: glyph_row = 8'd0;
            endcase
        end
    endfunction

    always @(*) begin
        char_valid = 1'b0;
        glyph = 3'd0;
        char_begin = 10'd0;
        local_x = 10'd0;
        local_y = 10'd0;
        row_bits = 8'd0;
        pix_data = 16'h0000;
        if ((pix_x < 10'd640) && (pix_y < 10'd480)) begin
            if (display_state == SCREEN_BAR) begin
                if      (pix_x < 10'd80)  pix_data = 16'hFFFF;
                else if (pix_x < 10'd160) pix_data = 16'hFFE0;
                else if (pix_x < 10'd240) pix_data = 16'h07FF;
                else if (pix_x < 10'd320) pix_data = 16'h07E0;
                else if (pix_x < 10'd400) pix_data = 16'hF81F;
                else if (pix_x < 10'd480) pix_data = 16'hF800;
                else if (pix_x < 10'd560) pix_data = 16'h001F;
                else                     pix_data = 16'h0000;
            end else if ((pix_y >= 10'd208) && (pix_y < 10'd272)) begin
                case (display_state)
                    SCREEN_MUST: begin
                        if ((pix_x >= 10'd144) && (pix_x < 10'd208)) begin
                            char_valid=1'b1; glyph=3'd0; char_begin=10'd144;
                        end else if ((pix_x >= 10'd240) && (pix_x < 10'd304)) begin
                            char_valid=1'b1; glyph=3'd1; char_begin=10'd240;
                        end else if ((pix_x >= 10'd336) && (pix_x < 10'd400)) begin
                            char_valid=1'b1; glyph=3'd2; char_begin=10'd336;
                        end else if ((pix_x >= 10'd432) && (pix_x < 10'd496)) begin
                            char_valid=1'b1; glyph=3'd3; char_begin=10'd432;
                        end
                    end
                    SCREEN_END: begin
                        if ((pix_x >= 10'd192) && (pix_x < 10'd256)) begin
                            char_valid=1'b1; glyph=3'd4; char_begin=10'd192;
                        end else if ((pix_x >= 10'd288) && (pix_x < 10'd352)) begin
                            char_valid=1'b1; glyph=3'd5; char_begin=10'd288;
                        end else if ((pix_x >= 10'd384) && (pix_x < 10'd448)) begin
                            char_valid=1'b1; glyph=3'd6; char_begin=10'd384;
                        end
                    end
                    default: begin end
                endcase
                if (char_valid) begin
                    local_x = pix_x - char_begin;
                    local_y = pix_y - 10'd208;
                    row_bits = glyph_row(glyph, local_y[5:3]);
                    pix_data = row_bits[3'd7-local_x[5:3]] ? 16'hFFFF : 16'h0000;
                end
            end
        end
    end
endmodule
