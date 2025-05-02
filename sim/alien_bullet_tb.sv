`timescale 1ns/1ps
import params::*;

module alien_bullet_tb;

    // Clock and sync
    logic pixel_clk;
    logic rst;
    logic fsync;

    // Inputs to DUT
    logic fire;
    logic [11:0] alien_x, alien_y;
    logic signed [11:0] hpos, vpos;

    // Outputs from DUT
    logic [7:0] pixel [0:2];
    logic bullet_active;

    // DUT
    alien_bullet dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .fire(fire),
        .alien_x(alien_x),
        .alien_y(alien_y),
        .hpos(hpos),
        .vpos(vpos),
        .pixel(pixel),
        .bullet_active(bullet_active)
    );

    // Clock generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    // Test sequence
    initial begin
        // Initial state
        rst = 1;
        fire = 0;
        alien_x = 12'd640;
        alien_y = 12'd100;
        hpos = 0;
        vpos = 0;

        // Reset pulse
        repeat (2) @(posedge pixel_clk);
        rst = 0;

        // Fire the bullet
        @(posedge pixel_clk);
        fire = 1;
        fsync = 1;
        @(posedge pixel_clk);
        fsync = 0;
        fire = 0;

        // Track bullet position
        repeat (100) begin
            fsync_pulse();
            scan_screen();
        end

        $finish;
    end

    // Simulate screen scan for one frame
    task scan_screen;
    begin
        for (int y = 0; y < VRES; y += 32) begin
            for (int x = 0; x < HRES; x += 32) begin
                hpos = x;
                vpos = y;
                @(posedge pixel_clk);
                if (bullet_active && (pixel[0] || pixel[1] || pixel[2])) begin
                    $display("Pixel active at (%0d, %0d) - RGB = %02x %02x %02x",
                             x, y, pixel[2], pixel[1], pixel[0]);
                end
            end
        end
    end
    endtask

    // fsync pulse
    task fsync_pulse;
    begin
        fsync = 1;
        @(posedge pixel_clk);
        fsync = 0;
        repeat (5) @(posedge pixel_clk);
    end
    endtask

endmodule
