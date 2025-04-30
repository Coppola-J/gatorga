`timescale 1ns/1ps

module top_tb;

    // Inputs to the top-level DUT
    logic clk125;
    logic right, left, fire;

    // Outputs (HDMI signals are not used in sim, but must be wired)
    logic tmds_tx_clk_p, tmds_tx_clk_n;
    logic [2:0] tmds_tx_data_p, tmds_tx_data_n;
    logic led_kawser;

    // Instantiate the DUT (top-level game module)
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

    // Clock Generation (125 MHz)
    initial clk125 = 0;
    always #4 clk125 = ~clk125;

    // Stimulus
    initial begin
        // Initial values
        right = 0;
        left  = 0;
        fire  = 0;
        
        // Wait some cycles for reset and paddle positioning
        repeat (1000) @(posedge clk125);

        // Fire once — assumes paddle is already centered
        fire = 1;
        @(posedge clk125);
        fire = 0;

        // Let bullet fly and simulate enough for possible alien hit
        repeat (100_000) @(posedge clk125);

        $display("Simulation complete.");
        $finish;
    end

endmodule
