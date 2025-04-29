`timescale 1ns/1ps

module top_tb;

    // Testbench signals
    logic clk125;
    logic right;
    logic left;
    logic fire;

    logic tmds_tx_clk_p;
    logic tmds_tx_clk_n;
    logic [2:0] tmds_tx_data_p;
    logic [2:0] tmds_tx_data_n;
    logic led_kawser;

    // Instantiate your top-level DUT
    top uut (
        .clk125(clk125),
        .right(right),
        .left(left),
        .fire(fire),
        .tmds_tx_clk_p(tmds_tx_clk_p),
        .tmds_tx_clk_n(tmds_tx_clk_n),
        .tmds_tx_data_p(tmds_tx_data_p),
        .tmds_tx_data_n(tmds_tx_data_n),
        .led_kawser(led_kawser)
    );

    // Clock generation
    initial clk125 = 0;
    always #4 clk125 = ~clk125; // 125 MHz clock = 8ns period

    initial begin
        // Initialize Inputs
        right = 0;
        left = 0;
        fire = 0;

        // Now controlled inside clock cycles
        repeat (100000) begin
            @(posedge clk125);

            if ($time > 200 && $time < 400) begin
                right <= 1;
            end else if ($time >= 400 && $time < 600) begin
                right <= 0;
                left <= 1;
            end else if ($time >= 600 && $time < 800) begin
                left <= 0;
            end

            if ($time >= 800 && $time < 820) begin
                fire <= 1;
            end else if ($time >= 820) begin
                fire <= 0;
            end
        end

        $finish;
    end

endmodule
