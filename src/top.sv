//-----------------------------------------------------------------------------
// Module: top
// Description: 
//   - Top-level system for Pong game on FPGA
//   - Connects HDMI transmit, ball (object), paddle, and gameover logic
//   - Combines video outputs and handles game-over detection and pause/restart
//-----------------------------------------------------------------------------

module top (
    input clk125,                // 125 MHz system clock
    input right,                 // Right button input (move paddle right)
    input left,                  // Left button input (move paddle left)

    // HDMI output signals
    output tmds_tx_clk_p,
    output tmds_tx_clk_n,
    output [2:0] tmds_tx_data_p,
    output [2:0] tmds_tx_data_n,

    output led_kawser             // Debug LED (always ON)
);

//-----------------------------------------------------------------------------
// Local Parameters
//-----------------------------------------------------------------------------
localparam HRES = 1280;            // Horizontal resolution
localparam VRES = 720;             // Vertical resolution

localparam PADDLE_W = 200;         // Paddle width
localparam PADDLE_H = 20;          // Paddle height

localparam COLOR_OBJ = 24'h00FF90; // Color of the moving object (ball)
localparam COLOR_PAD = 24'hEFE62E; // Color of the paddle
localparam COLOR_GMO = 24'hDD4F83; // Color of "Game Over" text

localparam GAMEOVER_H = 200;       // Height of "Game Over" bitmap
localparam GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1; // Center vertical start

localparam RESTART_PAUSE = 128;    // Pause frames before auto restart

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
object #(
    .HRES(HRES),
    .VRES(VRES),
    .COLOR(COLOR_OBJ),
    .PADDLE_H(PADDLE_H)
) object_inst (
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
paddle #(
    .HRES(HRES),
    .VRES(VRES),
    .PADDLE_W(PADDLE_W),
    .PADDLE_H(PADDLE_H),
    .COLOR(COLOR_PAD)
) paddle_inst (
    .pixel_clk(pixel_clk),
    .rst(rst || game_over),
    .fsync(fsync),
    .hpos(hpos),
    .vpos(vpos),
    .right(right),
    .left(left),
    .pixel(pixel_paddle),
    .active(active_paddle)
);

//-----------------------------------------------------------------------------
// Game Over Controller Instantiation
//-----------------------------------------------------------------------------
gameover_controller #(
    .HRES(HRES),
    .VRES(VRES),
    .PADDLE_H(PADDLE_H),
    .GAMEOVER_H(GAMEOVER_H),
    .GAMEOVER_VSTART(GAMEOVER_VSTART),
    .RESTART_PAUSE(RESTART_PAUSE),
    .COLOR_GMO(COLOR_GMO)
) gameover_controller_inst (
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

// Final RGB pixel mux
assign pixel[2] = use_gameover_pixels ? pixel_gameover[2] : (pixel_obj[2] | pixel_paddle[2]);
assign pixel[1] = use_gameover_pixels ? pixel_gameover[1] : (pixel_obj[1] | pixel_paddle[1]);
assign pixel[0] = use_gameover_pixels ? pixel_gameover[0] : (pixel_obj[0] | pixel_paddle[0]);

endmodule
