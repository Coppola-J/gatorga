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
// Moving Object (Ball) Instantiation
//-----------------------------------------------------------------------------
object object_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .pixel(pixel_obj),
    .active(active_obj)
);

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
    .paddle_center_x(paddle_center_x)    // <-- NEW
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


/*
//-----------------------------------------------------------------------------
// Alien Instantiation
//-----------------------------------------------------------------------------
alien alien_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .alien_hit(alien_hit),         // << connect from detector
    .pixel(pixel_alien),
    .active(active_alien),
    .alien_alive(alien_alive),
    .lhpos(alien_lhpos),
    .rhpos(alien_rhpos),
    .tvpos(alien_tvpos),
    .bvpos(alien_bvpos)
);

//-----------------------------------------------------------------------------
// Alien Instantiation
//-----------------------------------------------------------------------------

collision_controller collision_inst (
    .pixel_clk(pixel_clk),
    .rst(rst),
    .fsync(fsync),
    .bullet_active(bullet_active),
    .alien_alive(alien_alive),

    .bullet_left(bullet_left),
    .bullet_right(bullet_right),
    .bullet_top(bullet_top),
    .bullet_bottom(bullet_bottom),

    .alien_lhpos(alien_lhpos),
    .alien_rhpos(alien_rhpos),
    .alien_tvpos(alien_tvpos),
    .alien_bvpos(alien_bvpos),

    .alien_hit(alien_hit)
);
*/

// New Alien group signals
wire [$clog2(4*5+1)-1:0] aliens_remaining;  // adjust 4x5 if needed

// Alien signals
wire alien_hit;
wire [7:0] pixel_alien [0:2];
wire active_alien;
wire alien_alive;                  // Indicates if the alien is alive
wire signed [11:0] alien_lhpos;   // Left x-boundary of alien
wire signed [11:0] alien_rhpos;   // Right x-boundary of alien
wire signed [11:0] alien_tvpos;   // Top y-boundary of alien
wire signed [11:0] alien_bvpos;   // Bottom y-boundary of alien

alien_group #(
    .NUM_ROWS(4),
    .NUM_COLS(5)
) alien_group_inst (
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

    .alien_hit_out(alien_hit),
    .pixel(pixel_alien),
    .active(active_alien),
    .aliens_remaining(aliens_remaining)
);



//-----------------------------------------------------------------------------
// Game Over Controller Instantiation
//-----------------------------------------------------------------------------
gameover_controller gameover_controller_inst (
    .pixel_clk(pixel_clk),
    .rst(rst),
    .fsync(fsync),
    .active_obj(active_obj),
    .active_paddle(active_paddle),
    .hpos(hpos),
    .vpos(vpos),
    .game_over(game_over),
    .use_gameover_pixels(use_gameover_pixels),
    .pixel_gameover(pixel_gameover)
);

//-----------------------------------------------------------------------------
// Debug
//-----------------------------------------------------------------------------

wire debug [0:2];
assign debug[0] = bullet_active;
assign debug[1] = alien_hit;
assign debug[2] = alien_alive;
assign debug[3] = (bullet_left < alien_rhpos);


//-----------------------------------------------------------------------------
// Final Pixel Output
//-----------------------------------------------------------------------------

// (EXAMPLE) condition ? if true : if false

//assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] : (pixel_obj[2] | pixel_paddle[2] | pixel_bullet[2] | pixel_alien[2]);
//assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] : (pixel_obj[1] | pixel_paddle[1] | pixel_bullet[1] | pixel_alien[1]);
//assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] : (pixel_obj[0] | pixel_paddle[0] | pixel_bullet[0] | pixel_alien[0]);


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



endmodule
