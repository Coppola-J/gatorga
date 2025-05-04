//-----------------------------------------------------------------------------
// Module: scoreboard
// Description: 
//  Displays score of the current game, lives remaining, and round number.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
import params::*;

module scoreboard (
    input  logic        pixel_clk,
    input  logic        rst,
    input  logic        fsync,
    input  logic [11:0] hpos,
    input  logic [11:0] vpos,

    input  logic [$clog2(NUM_ROWS*NUM_COLS+1)-1:0] aliens_remaining,
    input  logic [1:0]  game_state,        // Use your enum to map to PLAY_GAME
    input  logic [1:0]  current_round,     // Round number from state machine
    input  logic [1:0]  lives_remaining,   // Lives left (0–3)

    output logic [7:0]  pixel [0:2],       // RGB output
    output logic        active             // Scoreboard is drawing here
);

    // Parameters for scoreboard area
    localparam BANNER_HEIGHT = 48;
    localparam BANNER_TOP    = 0;
    localparam BANNER_BOTTOM = BANNER_TOP + BANNER_HEIGHT;

    // Score calculation (aliens killed)
    localparam TOTAL_ALIENS = NUM_ROWS * NUM_COLS;
    logic [$clog2(TOTAL_ALIENS+1)-1:0] score;

    assign score = TOTAL_ALIENS - aliens_remaining;

    // Check if current pixel is inside banner area
    assign active = (vpos >= BANNER_TOP && vpos < BANNER_BOTTOM) && (game_state == 2'b10); // PLAY_GAME

    // Placeholder color scheme: blue background, white text zone
    always_comb begin
        if (active) begin
            // Simple solid banner background
            pixel[0] = 8'h20; // Blue
            pixel[1] = 8'h20;
            pixel[2] = 8'hAA;

            // TODO: Add text rendering or segment display later
        end else begin
            pixel[0] = 8'h00;
            pixel[1] = 8'h00;
            pixel[2] = 8'h00;
        end
    end

endmodule
