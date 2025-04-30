`timescale 1ns / 1ps
import params::*;

module bullet_tb;

    //---------------------------------------------------------------------
    // DUT Inputs and Outputs
    //---------------------------------------------------------------------
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

    //---------------------------------------------------------------------
    // DUT Instantiation
    //---------------------------------------------------------------------
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

    //---------------------------------------------------------------------
    // Clock and Sync Generation
    //---------------------------------------------------------------------
    always #1 pixel_clk = ~pixel_clk;

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

    //---------------------------------------------------------------------
    // Test Scenarios
    //---------------------------------------------------------------------
    task automatic test_random_bullet(input int frame_count);
        player_x = $urandom_range(0, HRES - 1); // Random horizontal position

        $display("Firing bullet from player_x = %0d", player_x);

        // Fire the bullet
        fire <= 1;
        wait_cycles(2);
        fire <= 0;

        // Latch fire event
        pulse_fsync();

        // Simulate N frames
        for (int i = 0; i < frame_count; i++) begin
            if (i % 20 == 0) begin
                $display("[%4d] bullet_active=%0b | left=%0d right=%0d | top=%0d bottom=%0d | pixel_active=%0b", 
                    i, bullet_active, bullet_left, bullet_right, bullet_top, bullet_bottom, 
                    (pixel[0] | pixel[1] | pixel[2]) != 8'h00
                );
            end

            if (i % 16 == 0) pulse_fsync(); // Simulate fsync every ~16 clocks

            wait_cycles(1);
        end
    endtask

    // Matching the player_x to the bullet position for simulation
    always_comb begin
        hpos <= player_x;
        vpos <= bullet_top + BULLET_H/2; // Simulate bullet position
    end


    // Fast simulated pixel clock (10x faster than normal for simulation)
    // Simulated horizontal and vertical counters
    /*always_ff @(posedge pixel_clk) begin
        if (rst) begin
            hpos <= 0;
            vpos <= 0;
        end else begin
            if (hpos < HRES - 1) begin
                hpos <= hpos + 1;
            end else begin
                hpos <= 0;
                if (vpos < VRES - 1) begin
                    vpos <= vpos + 1;
                end else begin
                    vpos <= 0;
                    fsync <= 1;  // Simulate frame start
                end
            end

            // Deassert fsync after one cycle
            if (fsync)
                fsync <= 0;
        end
    end*/


    //---------------------------------------------------------------------
    // Assertions
    //---------------------------------------------------------------------
    
    // Assertion: If bullet is active, pixel color must not be black
    always_ff @(posedge pixel_clk) begin
        if (bullet_active) begin
            assert ((pixel[0] != 8'h00) || (pixel[1] != 8'h00) || (pixel[2] != 8'h00))
            else $error("ASSERTION FAILED: Bullet is active but pixel is black at time %t", $time);
        end
    end

    // Assertion: Bullet bounding box must stay within screen bounds
    always_ff @(posedge pixel_clk) begin
        if (bullet_active) begin
            assert (bullet_left >= 0 && bullet_right < HRES &&
                    bullet_top  >= 0 && bullet_bottom < VRES)
            else $error("ASSERTION FAILED: Bullet bounds out of screen at time %t. L=%0d R=%0d T=%0d B=%0d", 
                        $time, bullet_left, bullet_right, bullet_top, bullet_bottom);
        end
    end


    //---------------------------------------------------------------------
    // Test Entry Point
    //---------------------------------------------------------------------
    initial begin
        $display("=== Starting bullet test ===");

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

        for (int i = 0; i < 100; i++) begin
            $display("=== Test iteration %0d ===", i);
            test_random_bullet(1000);
        end

        $display("=== Bullet test complete ===");
        $finish;
    end

endmodule
