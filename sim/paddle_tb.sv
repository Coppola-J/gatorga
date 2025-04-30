`timescale 1ns / 1ps
import params::*;

module paddle_tb;

    //---------------------------------------------------------------------
    // DUT Inputs and Outputs
    //---------------------------------------------------------------------
    // Clock & reset
    logic pixel_clk = 0;
    logic rst = 0;
    logic fsync = 0;

    // Inputs
    logic right = 0;
    logic left = 0;
    logic signed [11:0] hpos;
    logic signed [11:0] vpos;

    // Outputs
    logic [7:0] pixel [0:2];
    logic active;
    logic signed [11:0] paddle_center_x;

    //---------------------------------------------------------------------
    // DUT Instantiation
    //---------------------------------------------------------------------
    paddle uut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .hpos(hpos),
        .vpos(vpos),
        .right(right),
        .left(left),
        .pixel(pixel),
        .active(active),
        .paddle_center_x(paddle_center_x)
    );

    //---------------------------------------------------------------------
    // Clock and Sync Generation
    //---------------------------------------------------------------------
    always #5 pixel_clk = ~pixel_clk;

    // Frame sync helper
    task pulse_fsync();
        begin
            fsync = 1;
            @(posedge pixel_clk);
            fsync = 0;
        end
    endtask

    // Wait helper
    task wait_cycles(input int n);
        repeat (n) @(posedge pixel_clk);
    endtask


    //---------------------------------------------------------------------
    // Test Scenarios
    //---------------------------------------------------------------------
    task automatic run_random_movements(input int repeat_count);
        string direction;
        int frames;

        for (int j = 0; j < repeat_count; j++) begin
            // Random direction
            case ($urandom_range(0, 2))
                0: direction = "left";
                1: direction = "right";
                default: direction = "put";
            endcase

            // Random duration (in clock cycles)
            frames = $urandom_range(1000, 1000000);

            // Apply movement
            if (direction == "left")      left = 1;
            else if (direction == "right") right = 1;
            else begin
                left = 0;
                right = 0;
            end

            // Simulate frame-by-frame
            for (int i = 0; i < frames; i++) begin
                pulse_fsync(); // simulate frame

                wait_cycles(1);
                if (i % 100000 == 0) begin
                    $display("[%0t] Dir: %-5s | Frame %0d/%0d | Paddle X: %0d | RGB: %0h %0h %0h",
                        $time, direction, i, frames, paddle_center_x, pixel[2], pixel[1], pixel[0]);
                end
            end

            // Clear movement
            left = 0;
            right = 0;
        end
    endtask

    // Matching the player_x to the bullet position for simulation
    always_comb begin
        hpos <= paddle_center_x;
        vpos <= VRES - PADDLE_H/2; // Simulate bullet position
    end

    //---------------------------------------------------------------------
    // Test Entry Point
    //---------------------------------------------------------------------
    initial begin
        $display("=== Paddle Test Begin ===");
        rst = 1;
        wait_cycles(10);
        rst = 0;

        run_random_movements(20);  // Runs desired x2

        $display("=== Paddle Test Done ===");
        $finish;
    end

endmodule
