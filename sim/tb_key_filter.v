`timescale 1ns/1ps

module tb_key_filter;
    parameter integer DEBOUNCE_CYCLES = 8;
    reg clk = 1'b0;
    reg rst_n = 1'b1;
    reg key_in = 1'b1;
    wire key_db;
    wire click;
    integer clicks = 0;
    reg previous_click = 1'b0;
    always #10 clk = ~clk;
    key_filter #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) dut (
        .clk(clk), .rst_n(rst_n), .key_in(key_in), .key_db(key_db), .click(click)
    );
    always @(posedge clk) begin
        #1;
        if (click && previous_click) $fatal(1, "click wider than one cycle");
        if (click) clicks = clicks + 1;
        previous_click = click;
    end
    task hold_key;
        input value;
        input integer cycles;
        begin
            @(negedge clk); key_in = value;
            repeat (cycles) @(negedge clk);
        end
    endtask
    task expect_clicks;
        input integer expected;
        begin
            if (clicks != expected)
                $fatal(1, "expected clicks=%0d, actual=%0d", expected, clicks);
        end
    endtask
    initial begin
        $dumpfile("build/key_filter.vcd");
        $dumpvars(0, tb_key_filter);
        // Skip irrelevant 50 MHz edges during long physical-time waits.
        if (DEBOUNCE_CYCLES > 1000) $dumpoff;
        #3 rst_n = 1'b0;
        #24 rst_n = 1'b1;
        hold_key(1'b1, DEBOUNCE_CYCLES+8);
        // Two brief glitches must not count as a physical click.
        if (DEBOUNCE_CYCLES > 3) begin
            hold_key(1'b0, 2); hold_key(1'b1, 2);
            hold_key(1'b0, 2); hold_key(1'b1, DEBOUNCE_CYCLES+8);
            expect_clicks(0);
        end
        @(negedge clk); key_in = 1'b0;
        if (DEBOUNCE_CYCLES > 1000) begin
            repeat (DEBOUNCE_CYCLES-8) @(negedge clk);
            $dumpon;
            repeat (24) @(negedge clk);
            $dumpoff;
        end else repeat (DEBOUNCE_CYCLES+16) @(negedge clk);
        expect_clicks(1);
        hold_key(1'b0, 2*DEBOUNCE_CYCLES+8);
        expect_clicks(1); // Long hold must not retrigger.
        if (DEBOUNCE_CYCLES > 3) begin
            hold_key(1'b1, 2); hold_key(1'b0, 2);
            hold_key(1'b1, 2); hold_key(1'b0, 2);
        end
        hold_key(1'b1, DEBOUNCE_CYCLES+8);
        expect_clicks(1); // Release does not click.
        hold_key(1'b0, DEBOUNCE_CYCLES+8);
        expect_clicks(2);
        #3 rst_n = 1'b0;
        #24 rst_n = 1'b1; // Still holding key: old press is discarded.
        hold_key(1'b0, DEBOUNCE_CYCLES+12);
        expect_clicks(2);
        hold_key(1'b1, DEBOUNCE_CYCLES+8);
        hold_key(1'b0, DEBOUNCE_CYCLES+8);
        expect_clicks(3);
        $display("PASS tb_key_filter N=%0d: bounce/hold/release/reset", DEBOUNCE_CYCLES);
        $finish;
    end
endmodule
