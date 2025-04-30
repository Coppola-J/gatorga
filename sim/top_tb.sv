`timescale 1ns / 1ps
import params::*;

module top_tb;

    // Inputs
    logic clk125 = 0;
    logic right = 0;
    logic left = 0;
    logic fire = 0;

    // Outputs
    logic tmds_tx_clk_p;
    logic tmds_tx_clk_n;
    logic [2:0] tmds_tx_data_p;
    logic [2:0] tmds_tx_data_n;
    wire [0:3] debug; // Debug signals

    // Instantiate DUT
    top uut (
        .clk125(clk125),
        .right(right),
        .left(left),
        .fire(fire),
        .tmds_tx_clk_p(tmds_tx_clk_p),
        .tmds_tx_clk_n(tmds_tx_clk_n),
        .tmds_tx_data_p(tmds_tx_data_p),
        .tmds_tx_data_n(tmds_tx_data_n)
    );

    // Clock generation
    always #5 clk125 = ~clk125; // 100 MHz clock

    // Task to simulate holding left or right
    task move(input string direction, input int cycles);
        begin
            if (direction == "left") left = 1;
            else if (direction == "right") right = 1;
            repeat (cycles) @(posedge clk125);
            left = 0;
            right = 0;
        end
    endtask

    // Task to fire a bullet
    task fire_bullet;
        begin
            fire = 1;
            repeat (2) @(posedge clk125);
            fire = 0;
        end
    endtask

    // Sim procedure
    initial begin
        $display("=== TOP TB START ===");

        // Reset happens internally
        repeat (100) @(posedge clk125);

        // Move paddle to right and fire
        move("right", 80);
        fire_bullet();
        repeat (10000) @(posedge clk125);

        // Move paddle to left and fire
        move("left", 160);
        fire_bullet();
        repeat (10000) @(posedge clk125);

        // Center paddle and fire
        move("right", 40);
        fire_bullet();
        repeat (10000) @(posedge clk125);

        $display("=== TOP TB COMPLETE ===");
        $finish;
    end

endmodule
