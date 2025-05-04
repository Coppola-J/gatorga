//-----------------------------------------------------------------------------
// Module: top
// Description: 
//   - Top-level system for Pong game on FPGA
//   - Connects HDMI transmit, ball (object), paddle, and gameover logic
//   - Combines video outputs and handles game-over detection and pause/restart
//-----------------------------------------------------------------------------
import params::*;

module top (
    input clk125,                // 125 MHz system clock
    input right,                 // Right button input (move paddle right)
    input left,                  // Left button input (move paddle left)
    input fire,                  // Fire button input (fire bullet)
    input ready_up,             // Start button input (ready up)

    // HDMI output signals
    output tmds_tx_clk_p,
    output tmds_tx_clk_n,
    output [2:0] tmds_tx_data_p,
    output [2:0] tmds_tx_data_n,

    // Debug LED output
    output debug [0:3]
);


//-----------------------------------------------------------------------------
// Internal Wires and Registers
//-----------------------------------------------------------------------------
wire pixel_clk;                   // Pixel clock from HDMI transmitter
wire rst;                          // Reset signal
wire active;                       // Active video region
wire fsync;                        // Frame sync pulse

wire signed [11:0] hpos;           // Current horizontal pixel position
wire signed [11:0] vpos;           // Current vertical line position

wire [7:0] pixel [0:2];             // Final RGB output pixel (blue, green, red)

// Object (ball) signals
wire active_obj;
reg active_passing;
wire [7:0] pixel_obj [0:2];

// Paddle signals
wire active_paddle;
wire [7:0] pixel_paddle [0:2];
wire signed [11:0] paddle_center_x;
logic signed [11:0] paddle_left, paddle_right, paddle_top, paddle_bottom; // Paddle bounding box coordinates

//Bullet signals
wire [7:0] pixel_bullet [0:2];      // RGB pixel values from gameover controller
wire bullet_active;                // Bullet is currently being drawn
wire signed [11:0] bullet_center_x;
wire signed [11:0] bullet_top_y;
wire signed [11:0] bullet_left, bullet_right, bullet_top, bullet_bottom;


// Game over control
wire game_over;                       // Game over active signal
wire use_gameover_pixels;             // Whether to override with game over pixels
wire [7:0] pixel_gameover [0:2];      // RGB pixel values from gameover controller

//-----------------------------------------------------------------------------
// HDMI Transmitter Instantiation
//-----------------------------------------------------------------------------
hdmi_transmit hdmi_transmit_inst(
    .clk125(clk125),
    .pixel(pixel),
    .pixel_clk(pixel_clk),
    .rst(rst),                  // Outputting Reset signal
    .active(active),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .tmds_tx_clk_p(tmds_tx_clk_p),
    .tmds_tx_clk_n(tmds_tx_clk_n),
    .tmds_tx_data_p(tmds_tx_data_p),
    .tmds_tx_data_n(tmds_tx_data_n)
);

//-----------------------------------------------------------------------------
// Game State Machine Instantiation
//-----------------------------------------------------------------------------
logic [1:0] game_state;
logic [4:0] current_round;
logic game_over_SM; 
wire game_over_C; 

assign game_over = game_over_SM || game_over_C; // Combine game over signals

game_state_machine game_state_machine_inst (
    .pixel_clk(pixel_clk),
    .rst(rst),
    .fsync(fsync),
    .ready_up(ready_up),
    .all_aliens_dead(aliens_remaining == 0),
    .player_hit(alien_reached_paddle), // or custom signal
    .lives_remaining(2'd3), // TEMP: static value, wire up later
    .game_over(game_over_SM),
    .game_state(game_state),
    .round(current_round)
);

//-----------------------------------------------------------------------------
// Game State Machine Instantiation
//-----------------------------------------------------------------------------
wire [7:0] pixel_star [0:2];
wire active_star;

star_background star_bg_inst (
    .pixel_clk(pixel_clk),
    .rst(rst),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .game_state(game_state),
    .pixel(pixel_star),
    .active(active_star)
);


//-----------------------------------------------------------------------------
// Scoreboard Instantiation
//-----------------------------------------------------------------------------

/*
scoreboard scoreboard_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),

    .aliens_remaining(aliens_remaining), // Number of aliens remaining
    .game_state(game_state_machine_inst.game_state), // Current game state
    .current_round(game_state_machine_inst.current_round), // Current round number
    .lives_remaining(game_state_machine_inst.lives_remaining), // Lives left (0–3)

    .pixel(pixel_obj),                  // RGB output for scoreboard
    .active(active_obj)                 // Scoreboard is drawing here
);
*/

//-----------------------------------------------------------------------------
// Paddle Instantiation
//-----------------------------------------------------------------------------
paddle paddle_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .right(right),
    .left(left),
    .pixel(pixel_paddle),
    .active(active_paddle),
    .paddle_center_x(paddle_center_x),    // <-- NEW
    .paddle_left(paddle_left),
    .paddle_right(paddle_right),
    .paddle_top(paddle_top),
    .paddle_bottom(paddle_bottom)
);


//-----------------------------------------------------------------------------
// Bullet Instantiation (now with bounding box + active)
//-----------------------------------------------------------------------------
bullet bullet_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .fire(fire),
    .player_x(paddle_center_x),
    .hpos(hpos),
    .vpos(vpos),

    .pixel(pixel_bullet),

    .alien_hit(alien_hit),
    // Collision box outputs
    .bullet_active(bullet_active),
    .bullet_left(bullet_left),
    .bullet_right(bullet_right),
    .bullet_top(bullet_top),
    .bullet_bottom(bullet_bottom)
);

//-----------------------------------------------------------------------------
// Alien Group Instantiation
//-----------------------------------------------------------------------------

// New Alien group signals
wire [$clog2(NUM_ROWS*NUM_COLS+1)-1:0] aliens_remaining;  // adjust 4x5 if needed

// Alien signals
wire alien_hit;
wire [7:0] pixel_alien [0:2];
wire active_alien;
wire alien_alive;                  // Indicates if the alien is alive
wire signed [11:0] alien_lhpos;   // Left x-boundary of alien
wire signed [11:0] alien_rhpos;   // Right x-boundary of alien
wire signed [11:0] alien_tvpos;   // Top y-boundary of alien
wire signed [11:0] alien_bvpos;   // Bottom y-boundary of alien

alien_group alien_group_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),

    .hpos(hpos),
    .vpos(vpos),

    .speed(ENEMY_SPEED),                    // or a dynamic speed input later
    .bullet_active(bullet_active),
    .bullet_left(bullet_left),
    .bullet_right(bullet_right),
    .bullet_top(bullet_top),
    .bullet_bottom(bullet_bottom),

    .paddle_left(paddle_left),
    .paddle_right(paddle_right),
    .paddle_top(paddle_top),
    .paddle_bottom(paddle_bottom),
    .alien_reached_paddle(alien_reached_paddle),  // NEW OUTPUT


    .alien_hit_out(alien_hit),
    .pixel(pixel_alien),
    .active(active_alien),
    .aliens_remaining(aliens_remaining)
);



//-----------------------------------------------------------------------------
// Game Over Controller Instantiation
//-----------------------------------------------------------------------------
logic alien_reached_paddle; // Signal to indicate if an alien has reached the paddle

gameover_controller gameover_controller_inst (
    .pixel_clk(pixel_clk),
    .rst(rst),
    .fsync(fsync),
    .active_obj(active_obj),
    .alien_reached_paddle(alien_reached_paddle),
    .active_paddle(active_paddle),
    .hpos(hpos),
    .vpos(vpos),
    .game_over(game_over_C),
    .use_gameover_pixels(use_gameover_pixels),
    .pixel_gameover(pixel_gameover)
);

//-----------------------------------------------------------------------------
// Debug
//-----------------------------------------------------------------------------

wire debug [0:2];
assign debug[0] = bullet_active;
assign debug[1] = game_over_SM;
assign debug[2] = game_over_C;
assign debug[3] = game_over;


//-----------------------------------------------------------------------------
// Final Pixel Output
//-----------------------------------------------------------------------------

// (EXAMPLE) condition ? if true : if false

//assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] : (pixel_obj[2] | pixel_paddle[2] | pixel_bullet[2] | pixel_alien[2]);
//assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] : (pixel_obj[1] | pixel_paddle[1] | pixel_bullet[1] | pixel_alien[1]);
//assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] : (pixel_obj[0] | pixel_paddle[0] | pixel_bullet[0] | pixel_alien[0]);

/*
assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] :
                  pixel_alien[2]      ? pixel_alien[2]    :
                  pixel_paddle[2]     ? pixel_paddle[2]   :
                  pixel_bullet[2]     ? pixel_bullet[2]   :
                                        1'b0;

assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] :
                  pixel_alien[1]      ? pixel_alien[1]    :
                  pixel_paddle[1]     ? pixel_paddle[1]   :
                  pixel_bullet[1]     ? pixel_bullet[1]   :
                                        1'b0;

assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] :
                  pixel_alien[0]      ? pixel_alien[0]    :
                  pixel_paddle[0]     ? pixel_paddle[0]   :
                  pixel_bullet[0]     ? pixel_bullet[0]   :
                                        1'b0;
*/

// TODO: Need to do active logic here, outside of modules. Need to 
// use a priority encoder to determine which pixel to use.

assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] :
                  pixel_alien[2]      ? pixel_alien[2]    :
                  pixel_paddle[2]     ? pixel_paddle[2]   :
                  pixel_bullet[2]     ? pixel_bullet[2]   :
                  pixel_star[2]       ? pixel_star[2]     :
                                        1'b0;

assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] :
                  pixel_alien[1]      ? pixel_alien[1]    :
                  pixel_paddle[1]     ? pixel_paddle[1]   :
                  pixel_bullet[1]     ? pixel_bullet[1]   :
                  pixel_star[1]       ? pixel_star[1]     :
                                        1'b0;

assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] :
                  pixel_alien[0]      ? pixel_alien[0]    :
                  pixel_paddle[0]     ? pixel_paddle[0]   :
                  pixel_bullet[0]     ? pixel_bullet[0]   :
                  pixel_star[0]       ? pixel_star[0]     :
                                        1'b0;




endmodule
