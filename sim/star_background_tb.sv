`timescale 1ns/1ps
import params::*;

module star_background_tb;

    logic pixel_clk;
    logic rst;
    logic fsync;
    logic signed [11:0] hpos;
    logic signed [11:0] vpos;
    logic [1:0] game_state;

    logic [7:0] pixel [0:2];
    logic active;

    // Instantiate DUT
    star_background #(8) dut ( // Use 8 stars for easier debug
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .hpos(hpos),
        .vpos(vpos),
        .game_state(game_state),
        .pixel(pixel),
        .active(active)
    );

    // Clock generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    task fsync_pulse;
        begin
            fsync = 1;
            @(posedge pixel_clk);
            fsync = 0;
        end
    endtask

    initial begin
        $display("Starting star_background TB...");

        rst = 1;
        fsync = 0;
        hpos = 0;
        vpos = 0;
        game_state = 2'b01; // Not GAMEOVER

        // Apply reset
        repeat (4) @(posedge pixel_clk);
        rst = 0;

        // Let a few frames go by with star movement
        repeat (4) begin
            fsync_pulse();
            repeat (1000) @(posedge pixel_clk);
        end

        // Simulate scanning through pixels
        for (int y = 0; y < VRES; y++) begin
            for (int x = 0; x < HRES; x++) begin
                hpos = x;
                vpos = y;
                @(posedge pixel_clk);

                if (active) begin
                    $display("Star visible at (%0d, %0d) -> RGB = %h%h%h", hpos, vpos, pixel[2], pixel[1], pixel[0]);
                end
            end
        end

        $display("Star background test complete.");
        $finish;
    end

endmodule
