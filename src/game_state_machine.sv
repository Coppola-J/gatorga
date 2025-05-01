`timescale 1ns/1ps
import params::*;


module game_state_machine (
    input pixel_clk,
    input rst,
    input fsync,
    input active_obj,
    input active_paddle,
    input signed [11:0] hpos,
    input signed [11:0] vpos,

    output logic game_over,                 // Game over active
    output logic use_gameover_pixels,       // Should top use gameover pixels?
    output logic [7:0] pixel_gameover [0:2] // Game over RGB pixels
);

reg [4:0] level_counter; // Counter for levels

typedef enum logic [1:0] {
    START_SCREEN,
    NEXT_LEVEL,
    PLAY_GAME,
    GAMEOVER_SCREEN
} state_t;

state_t state_r, next_state;

always_ff @(posedge pixel_clk, posedge rst) begin
    if (rst) state_r <= START_SCREEN;
    else state_r <= next_state;
end


always_comb begin
    next_state = state_r;           // Next state will always be currwent state unless changed
    
    case (state_r)
        START_SCREEN: begin
            // Display start screen, wait for a bit, and if ready_up, then go to next level
            if (ready_up == 1)begin
                level_counter = 1;
                next_state = NEXT_LEVEL;
            end else begin
                level_counter = 0;
                // next_state = START_SCREEN; Unecessary since next_state will always be current state, unless changed
            end
        end

        NEXT_LEVEL: begin
            // Display level, increment level counter, reset aliens and increase speed, go to play game
            if (level_counter == 1) begin 
                //default alien values
                next_state = PLAY_GAME;
            end else begin
                level_counter = level_counter + 1;
                // Reset aliens and increase speed
                next_state = PLAY_GAME;
            end
        end

        PLAY_GAME: begin
            // If all aliens are dead, wait for a bit, and go to next level
            // If no lives are left, and the player gets hit again, go to game over screen
            out = 4'b0100;
            next_state = STATE3;
        end

        GAMEOVER_SCREEN: begin
            // Display game over screen, wait for a bit, and go to start screen
        end
    endcase
end

endmodule