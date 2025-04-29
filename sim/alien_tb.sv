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

    // Instantiate the DUT (Device Under Test)
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
        .alien_alive(alien_alive)
    );

    // Clock Generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;  // 100 MHz clock

    // Test Sequence
    initial begin
        // Initial Values
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
        repeat (3) begin
            fsync = 1; #10; fsync = 0; #90;
        end

        // Fire a bullet that will NOT hit the alien
        bullet_active = 1;
        bullet_x = 10;   // Way off to the left
        bullet_y = 110;  // Somewhere middle height

        // Wait a few frames
        repeat (3) begin
            fsync = 1; #10; fsync = 0; #90;
        end

        if (!alien_alive) $display("Error: Unexpected hit detected! (should miss)");

        // Fire a bullet directly at alien's current position
        bullet_active = 1;
        bullet_x = 105;   // Near alien (alien initialized at x=100..120 approx)
        bullet_y = 105;   // Near alien vertical

        // Wait a few frames
        repeat (1) begin
            fsync = 1; #10; fsync = 0; #90;
        end

        if (alien_alive) $display("Error: Expected hit, but none detected!");

        // Check if alien is now dead
        if (!alien_alive) begin
            $display("Alien correctly detected hit and died. Test Passed!");
        end else begin
            $display("Error: Alien should be dead after hit!");
        end

        $finish;
    end

endmodule
