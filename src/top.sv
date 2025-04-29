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

    output led_kawser             // Debug LED (always ON)
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
    .rst(rst),
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
// Bullet Instantiation
//-----------------------------------------------------------------------------
wire signed [11:0] bullet_center_x;
wire signed [11:0] bullet_top_y;


bullet bullet_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .fire(fire),
    .player_x(paddle_center_x),  // Already wired from paddle
    .hpos(hpos),
    .vpos(vpos),
    .pixel(pixel_bullet),
    .active(active_bullet),
    .bullet_center_x(bullet_center_x),
    .bullet_top_y(bullet_top_y)
);


//-----------------------------------------------------------------------------
// Alien Instantiation
//-----------------------------------------------------------------------------
wire [7:0] pixel_alien [0:2];
wire active_alien;

alien alien_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .bullet_x(bullet_center_x),
    .bullet_y(bullet_top_y),
    .bullet_active(active_bullet),
    .pixel(pixel_alien),
    .active(active_alien),
    .alien_alive(alien_alive)
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

// Final Pixel Output Logic
assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] : (pixel_obj[2] | pixel_paddle[2] | pixel_bullet[2] | pixel_alien[2]);
assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] : (pixel_obj[1] | pixel_paddle[1] | pixel_bullet[1] | pixel_alien[1]);
assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] : (pixel_obj[0] | pixel_paddle[0] | pixel_bullet[0] | pixel_alien[0]);


endmodule
