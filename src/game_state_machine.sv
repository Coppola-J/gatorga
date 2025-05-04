//-----------------------------------------------------------------------------
// Module: game_state_machine
// Description: 
//  Used to control the game state logic. Outputs control signals to advance levels, start and stop game. 
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
import params::*;


module game_state_machine (
    input  logic        pixel_clk,
    input  logic        rst,
    input  logic        fsync,
    input  logic        ready_up,            // Start button
    input  logic        all_aliens_dead,     // aliens_remaining == 0
    input  logic        player_hit,          // alien reached paddle or bullet hit player
    input  logic [1:0]  lives_remaining,

    output logic        game_over,
    output logic [1:0]  game_state,          // Export current state
    output logic [4:0]  round
);

// TODO: For now lets use gameover as control signal for start and end of game, as well as round. 
// Lets make sure that all works, then we can move on to adding a ready_up screen and scoreboard. 


//-----------------------------------------------------------------------------
// Internal Registers
//-----------------------------------------------------------------------------
    logic [4:0] level_counter; // Counter for levels

    typedef enum logic [1:0] {
        START_SCREEN,
        NEXT_LEVEL,
        PLAY_GAME,
        GAMEOVER_SCREEN
    } state_t;

    state_t state_r, next_state;

    always_ff @(posedge pixel_clk, posedge rst) begin
        if (rst) begin
            state_r <= START_SCREEN;
            level_counter <= 5'b00000;
        end else begin
            state_r <= next_state;
        end
    end

//-----------------------------------------------------------------------------
// Ready_up Button Debouncing
//-----------------------------------------------------------------------------
    reg [0:2] ready_ff;                  // Debounce shift register
    reg ready_latched;                   // Latch to detect single fire press

    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            ready_ff <= 3'b000;
            ready_latched <= 1'b0;
        end else begin
            ready_ff <= {ready_up, ready_ff[0:1]};

            if (~ready_latched && ready_ff[2]) begin
                ready_latched <= 1'b1;
            end

            if (fsync) begin
                ready_latched <= 1'b0; // Clear latch each frame
            end
        end
    end

//-----------------------------------------------------------------------------
// State machine logic
//-----------------------------------------------------------------------------

always_comb begin
    next_state = state_r;           // Next state will always be currwent state unless changed
    
    case (state_r)
        START_SCREEN: begin
            // Display start screen, wait for a bit, and if ready_up, then go to next level
            if (ready_latched == 1)begin
                level_counter = 5'b000001;
                next_state = NEXT_LEVEL;
            end else begin
                level_counter = 5'b00000;
                game_over = 1'b1;
                // next_state = START_SCREEN; Unecessary since next_state will always be current state, unless changed
            end
        end

        NEXT_LEVEL: begin
            // Display level, increment level counter, reset aliens and increase speed, go to play game
            if (level_counter == 0) begin 
                level_counter = level_counter + 1;
                game_over = 1'b1;
                next_state = PLAY_GAME;
            end else begin
                level_counter = level_counter + 1;
                // Reset aliens and increase speed
                next_state = PLAY_GAME;
            end
        end

        PLAY_GAME: begin
            game_over = 1'b0;
            if (player_hit) begin
                // If player is hit, decrement lives and go to game over screen if no lives left
                if (lives_remaining == 0) begin
                    next_state = GAMEOVER_SCREEN;
                end else begin
                    next_state = PLAY_GAME; // Stay in play game state
                end
            end else if (all_aliens_dead) begin
                // If all aliens are dead, go to next level
                next_state = NEXT_LEVEL;
            end else begin
                next_state = PLAY_GAME; // Stay in play game state
            end
        end

        GAMEOVER_SCREEN: begin
            game_over = 1'b1;
            if (ready_latched) begin
                // If ready_up is pressed, go back to start screen
                next_state = START_SCREEN;
            end else begin
                // Stay in game over screen until ready_up is pressed
                next_state = GAMEOVER_SCREEN; // Stay in game over state
            end
            // Display game over screen, wait for a bit, and go to start screen
        end
    endcase
end

    // Export game state and round
    assign game_state = state_r;
    assign round = level_counter;

endmodule