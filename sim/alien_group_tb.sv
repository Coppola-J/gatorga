`timescale 1ns/1ps
import params::*;

module alien_group_tb;

    // Clock and sync
    logic pixel_clk;
    logic rst;
    logic fsync;

    // Pixel scanning
    logic signed [11:0] hpos, vpos;

    // Bullet (shared input)
    logic bullet_active;
    logic signed [11:0] bullet_left, bullet_right, bullet_top, bullet_bottom;

    // Outputs from DUT
    logic [7:0] pixel [0:2];
    logic active;
    logic alien_hit_out;
    logic [$clog2(4 * 5 + 1)-1:0] aliens_remaining;

    // Device under test
    alien_group #(4, 5) dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .hpos(hpos),
        .vpos(vpos),
        .speed(8'd1),
        .bullet_active(bullet_active),
        .bullet_left(bullet_left),
        .bullet_right(bullet_right),
        .bullet_top(bullet_top),
        .bullet_bottom(bullet_bottom),
        .alien_hit_out(alien_hit_out),
        .aliens_remaining(aliens_remaining),
        .pixel(pixel),
        .active(active)
    );

    // Clock generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    // Test sequence
    initial begin
        rst = 1;
        fsync = 0;
        bullet_active = 0;
        hpos = 0;
        vpos = 0;

        // Reset pulse
        repeat (2) @(posedge pixel_clk);
        rst = 0;

        // Wait a few frames
        repeat (5) fsync_pulse();

        // Fire a bullet at center of top-left alien
        fire_bullet(ALIEN_START + 4, ALIEN_START + 4);
        repeat (2) @(posedge pixel_clk);
        fsync_pulse();

        // Check for a hit
        if (alien_hit_out)
            $display("PASS: Hit detected");
        else
            $display("FAIL: No hit when expected");

        // Confirm alien count decreased
        $display("Aliens remaining: %0d", aliens_remaining);

        $finish;
    end

    task fire_bullet(input signed [11:0] cx, input signed [11:0] cy);
    begin
        bullet_active = 1;
        bullet_left   = cx - (BULLET_W >> 1);
        bullet_right  = cx + (BULLET_W >> 1);
        bullet_top    = cy;
        bullet_bottom = cy + BULLET_H;
    end
    endtask

    task fsync_pulse;
    begin
        fsync = 1;
        @(posedge pixel_clk);
        fsync = 0;
        repeat (5) @(posedge pixel_clk);
    end
    endtask

endmodule
