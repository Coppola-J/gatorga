//-----------------------------------------------------------------------------
// Module: params
// Description: 
//  Parameter definitions for all entitiies within the game. 
//-----------------------------------------------------------------------------

package params;

//-----------------------------------------------------------------------------
// Screen bounds and resolution
//-----------------------------------------------------------------------------
    parameter HRES = 1280;
    parameter VRES = 720;


//-----------------------------------------------------------------------------
//  Player paddle
//-----------------------------------------------------------------------------
    parameter PADDLE_VEL = 16;
    parameter PADDLE_W = 50;                // Paddle width in pixels
    parameter PADDLE_H = 20;                // Paddle height in pixels
    parameter PADDLE_COLOR = 24'hFF3C00;    // Paddle color (RGB 24-bit)
    parameter PUT = 2'h0;                   // Paddle idle (no movement)
    parameter LEFT = 2'h1;                  // Move left
    parameter RIGHT = 2'h2;                 // Move right

//-----------------------------------------------------------------------------
// Ball object from original pong game
//-----------------------------------------------------------------------------
    parameter OBJECT_VEL = 0;    
    parameter OBJECT_COLOR = 24'h00FF90;         // Object color (neon green)
    parameter OBJ_SIZE = 50;              // Ball size
    parameter [1:0] DOWN_RIGHT = 2'b00;   // Moving down and right
    parameter [1:0] DOWN_LEFT  = 2'b01;   // Moving down and left
    parameter [1:0] UP_RIGHT   = 2'b10;   // Moving up and right
    parameter [1:0] UP_LEFT    = 2'b11;   // Moving up and left

//-----------------------------------------------------------------------------
// Game over screen
//-----------------------------------------------------------------------------
    parameter GAMEOVER_H = 200;
    parameter GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1;
    parameter RESTART_PAUSE = 128;
    parameter COLOR_GMO = 24'hDD4F83;


//-----------------------------------------------------------------------------
// Player bullet
//-----------------------------------------------------------------------------
    parameter BULLET_W = 4;
    parameter BULLET_H = 16;
    parameter BULLET_SPEED = 16;
    parameter [23:0] BULLET_COLOR = 24'hFFFFFF; // White

//-----------------------------------------------------------------------------
// Enemies
//-----------------------------------------------------------------------------
    parameter ENEMY_W = 32;
    parameter ENEMY_H = 28;
    parameter ENEMY_SPEED = 1;           // Might need to be adjusted to account for different speeds at higher levels
    parameter [23:0] ENEMY_COLOR = 24'h00AAFF; // Blueish
    parameter DROP = 32;
    parameter ALIEN_START = (VRES - PADDLE_H - BULLET_H) - (DROP * 17); // Used for clean collision detection (alien & bullet will occur on the same pixels)
    parameter SPACING_X = 50;
    parameter SPACING_Y = 16;
    parameter ENEMY_BULLET_COLOR = 24'hFF0000; // Red
    parameter NUM_COLS = 6;
    parameter NUM_ROWS = 10;
    parameter ALIEN_HSTART = (HRES - ((NUM_COLS * ENEMY_W) + ((NUM_COLS - 1) * SPACING_X))) / 2;
    parameter ALIEN_VSTART = (VRES - PADDLE_H - BULLET_H) - (DROP * 18);
    parameter ENEMY_BULLET_SPEED = 1;


endpackage
