`timescale 1ns/1ps
import params::*;

module game_state_machine_tb;

    // DUT Inputs
    logic pixel_clk;
    logic rst;
    logic fsync;
    logic ready_up;
    logic all_aliens_dead;
    logic player_hit;
    logic [1:0] lives_remaining;

    // DUT Outputs
    logic game_over;
    logic [1:0] game_state;
    logic [4:0] round;

    // Instantiate DUT
    game_state_machine dut (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .ready_up(ready_up),
        .all_aliens_dead(all_aliens_dead),
        .player_hit(player_hit),
        .lives_remaining(lives_remaining),
        .game_over(game_over),
        .game_state(game_state),
        .round(round)
    );

    // Clock generation
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk; // 100 MHz clock

    // FSYNC generator
    task fsync_pulse;
        begin
            fsync = 1;
            @(posedge pixel_clk);
            fsync = 0;
        end
    endtask

    initial begin
        // Initialize
        rst = 1;
        fsync = 0;
        ready_up = 0;
        all_aliens_dead = 0;
        player_hit = 0;
        lives_remaining = 2;

        // Wait a few clocks
        repeat (5) @(posedge pixel_clk);

        // Release reset
        rst = 0;

        // Initial state: START_SCREEN
        $display("T=%0t | State: %0d | Game Over: %0b", $time, game_state, game_over);

        // Simulate pressing start (ready_up)
        ready_up = 1;
        fsync_pulse(); // Register the latch
        @(posedge pixel_clk);
        ready_up = 0;
        fsync_pulse();

        // Wait and check transition to PLAY_GAME
        repeat (10) @(posedge pixel_clk);
        $display("T=%0t | State: %0d | Round: %0d | Game Over: %0b", $time, game_state, round, game_over);

        // Simulate all aliens being dead
        all_aliens_dead = 1;
        fsync_pulse();
        repeat (2) @(posedge pixel_clk);
        all_aliens_dead = 0;

        repeat (10) @(posedge pixel_clk);
        $display("T=%0t | State: %0d | Round: %0d", $time, game_state, round);

        // Simulate player getting hit with no lives left
        lives_remaining = 0;
        player_hit = 1;
        fsync_pulse();
        repeat (2) @(posedge pixel_clk);
        player_hit = 0;

        repeat (10) @(posedge pixel_clk);
        $display("T=%0t | State: %0d | Game Over: %0b", $time, game_state, game_over);

        $finish;
    end

endmodule
