`timescale 1ns / 1ps
import params::*;

module bullet_tb;

    // DUT inputs
    logic pixel_clk = 0;
    logic rst = 0;
    logic fsync = 0;
    logic fire = 0;
    logic signed [11:0] player_x;
    logic signed [11:0] hpos, vpos;

    // DUT outputs
    logic [7:0] pixel [0:2];
    logic bullet_active;
    logic signed [11:0] bullet_left, bullet_right, bullet_top, bullet_bottom;

    // Instantiate DUT
    bullet uut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .fire(fire),
        .player_x(player_x),
        .hpos(hpos),
        .vpos(vpos),
        .pixel(pixel),
        .bullet_active(bullet_active),
        .bullet_left(bullet_left),
        .bullet_right(bullet_right),
        .bullet_top(bullet_top),
        .bullet_bottom(bullet_bottom)
    );

    // Clock generation (100 MHz)
    always #5 pixel_clk = ~pixel_clk;

    // Task: wait N rising clock edges
    task wait_cycles(input int n);
        repeat (n) @(posedge pixel_clk);
    endtask

    // Task: pulse fsync (1 cycle)
    task pulse_fsync;
        begin
            fsync <= 1;
            wait_cycles(1);
            fsync <= 0;
        end
    endtask

    initial begin
        $display("=== Starting bullet test ===");

        // Screen probe location (for active flag)
        hpos = HRES - 10; // Near right screen edge
        vpos = VRES - PADDLE_H - BULLET_H;

        // Reset
        rst <= 1;
        wait_cycles(5);
        rst <= 0;

        // Place paddle near right edge
        player_x = HRES - 20;

        // Fire the bullet
        fire <= 1;
        wait_cycles(2);
        fire <= 0;

        // Latch fire event
        pulse_fsync();

        // Simulate 1000 cycles (about 50 frames)
        for (int i = 0; i < 1000; i++) begin
            if (i % 20 == 0) begin
                $display("[%4d] bullet_active=%0b | left=%0d right=%0d | top=%0d bottom=%0d | pixel_active=%0b", 
                    i, bullet_active, bullet_left, bullet_right, bullet_top, bullet_bottom, 
                    (pixel[0] | pixel[1] | pixel[2]) != 8'h00
                );
            end

            if (i % 16 == 0) pulse_fsync(); // simulate fsync every ~16 clocks

            wait_cycles(1);
        end

        // Place paddle near right edge
        player_x = 20;

        // Fire the bullet
        fire <= 1;
        wait_cycles(2);
        fire <= 0;

        // Simulate 1000 cycles (about 50 frames)
        for (int i = 0; i < 1000; i++) begin
            if (i % 20 == 0) begin
                $display("[%4d] bullet_active=%0b | left=%0d right=%0d | top=%0d bottom=%0d | pixel_active=%0b", 
                    i, bullet_active, bullet_left, bullet_right, bullet_top, bullet_bottom, 
                    (pixel[0] | pixel[1] | pixel[2]) != 8'h00
                );
            end

            if (i % 16 == 0) pulse_fsync(); // simulate fsync every ~16 clocks

            wait_cycles(1);
        end

        $display("=== Bullet test complete ===");
        $finish;
    end

endmodule
