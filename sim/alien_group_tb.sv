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

    // Alien bullet coordinates
    logic signed [11:0] alien_bullet_x, alien_bullet_y;

    // Outputs from DUT
    logic [7:0] pixel [0:2];
    logic active;
    logic alien_hit_out;
    logic [$clog2(NUM_COLS * NUM_ROWS + 1)-1:0] aliens_remaining;

    // Device under test
    alien_group #(4, 5) dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .hpos(hpos),
        .vpos(vpos),
        .speed(8'd1),
        .bullet_active(bullet_active),
        .alien_hit_out(alien_hit_out),
        .aliens_remaining(aliens_remaining),
        .pixel(pixel),
        .active(active),
        .alien_bullet_x(alien_bullet_x),
        .alien_bullet_y(alien_bullet_y)
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

        // Wait and display bullet info
        repeat (20000) begin
            fsync_pulse();
        end

        $finish;
    end

    task fsync_pulse;
    begin
        fsync = 1;
        @(posedge pixel_clk);
        fsync = 0;
        repeat (5) @(posedge pixel_clk);

        if (dut.alien_bullet_active) begin
            $display("Alien bullet at X: %0d, Y: %0d", alien_bullet_x, alien_bullet_y);
        end
    end
    endtask

endmodule
