`timescale 1ns/1ps

module alien_tb;

    // Testbench Signals
    logic pixel_clk;
    logic rst;
    logic fsync;
    logic signed [11:0] hpos, vpos;

    logic signed [11:0] bullet_x, bullet_y;
    logic bullet_active;

    logic [7:0] pixel [0:2];
    logic active;
    logic alien_alive;
    logic alien_hit;

    // Instantiate DUT
    alien uut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .hpos(hpos),
        .vpos(vpos),
        .bullet_x(bullet_x),
        .bullet_y(bullet_y),
        .bullet_active(bullet_active),
        .pixel(pixel),
        .active(active),
        .alien_alive(alien_alive),
        .alien_hit(alien_hit)
    );

    // Clock Generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;  // 100 MHz clock

    // Test Sequence
    initial begin
        // Initialize
        rst = 1;
        fsync = 0;
        hpos = 0;
        vpos = 0;
        bullet_x = 0;
        bullet_y = 0;
        bullet_active = 0;

        // Reset pulse
        #20;
        rst = 0;

        // Wait a few frames
        repeat (5) @(posedge pixel_clk);
        
        // Bullet 1: Miss (way off to the side)
        fire_bullet(50, 110);
        repeat (2) @(posedge pixel_clk);
        fsync_pulse();
        check_no_hit();

        // Bullet 2: Close miss (near but not touching)
        fire_bullet(90, 110);
        repeat (2) @(posedge pixel_clk);
        fsync_pulse();
        check_no_hit();

        // Bullet 3: Direct hit
        fire_bullet(105, 105);  // Alien at ~100..120, ~100..120
        repeat (2) @(posedge pixel_clk);
        fsync_pulse();
        check_hit();

        // Bullet 4: Try again after dead
        fire_bullet(105, 105);
        repeat (2) @(posedge pixel_clk);
        fsync_pulse();
        check_still_dead();

        $display("Test completed.");
        $finish;
    end

    // -----------------------------------------------------------------------------
    // Helper Tasks
    // -----------------------------------------------------------------------------

    task fire_bullet(input signed [11:0] x, input signed [11:0] y);
    begin
        bullet_active = 1;
        bullet_x = x;
        bullet_y = y;
    end
    endtask

    task fsync_pulse;
    begin
        fsync = 1;
        #10;
        fsync = 0;
        #90;
    end
    endtask

    task check_no_hit;
    begin
        if (!alien_alive) begin
            $display("Error: Alien died unexpectedly during miss!");
        end else begin
            $display("PASS: No hit, alien still alive.");
        end
    end
    endtask

    task check_hit;
    begin
        if (!alien_alive) begin
            $display("PASS: Alien correctly detected hit and died.");
        end else begin
            $display("Error: Alien should be dead after hit!");
        end
    end
    endtask

    task check_still_dead;
    begin
        if (alien_alive) begin
            $display("Error: Alien resurrected after death!");
        end else begin
            $display("PASS: Dead alien stays dead after another bullet.");
        end
    end
    endtask

endmodule
