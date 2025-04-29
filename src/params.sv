//-----------------------------------------------------------------------------
// Global Parameters File for Space Invaders
//-----------------------------------------------------------------------------

package params;

    // Screen resolution
    parameter int HRES = 1280;
    parameter int VRES = 720;

    // Player paddle
    parameter PADDLE_VEL = 16;
    parameter PADDLE_W = 50;                // Paddle width in pixels
    parameter PADDLE_H = 20;                // Paddle height in pixels
    parameter PADDLE_COLOR = 24'hFF3C00;    // Paddle color (RGB 24-bit)
    parameter PUT = 2'h0;                   // Paddle idle (no movement)
    parameter LEFT = 2'h1;                  // Move left
    parameter RIGHT = 2'h2;                 // Move right

    // Ball (object)
    parameter OBJECT_VEL = 0;    
    parameter OBJECT_COLOR = 24'h00FF90;         // Object color (neon green)
    parameter OBJ_SIZE = 50;              // Ball size
    parameter [1:0] DOWN_RIGHT = 2'b00;   // Moving down and right
    parameter [1:0] DOWN_LEFT  = 2'b01;   // Moving down and left
    parameter [1:0] UP_RIGHT   = 2'b10;   // Moving up and right
    parameter [1:0] UP_LEFT    = 2'b11;   // Moving up and left

    // Game Over Text
    parameter GAMEOVER_H = 200;
    parameter GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1;
    parameter RESTART_PAUSE = 128;
    parameter COLOR_GMO = 24'hDD4F83;


    // Bullet
    parameter int BULLET_W = 4;
    parameter int BULLET_H = 16;
    parameter int BULLET_SPEED = 16;
    parameter logic [23:0] BULLET_COLOR = 24'hFFFFFF; // White

    // Enemies
    parameter int ENEMY_W = 32;
    parameter int ENEMY_H = 28;
    parameter int ENEMY_SPEED = 2;
    parameter logic [23:0] ENEMY_COLOR = 24'h00AAFF; // Blueish
    parameter int DROP = 32;

endpackage
