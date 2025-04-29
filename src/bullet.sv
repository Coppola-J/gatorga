`timescale 1ns/1ps
import params::*;

module bullet (
    input pixel_clk,
    input rst,
    input fsync,
    input fire,                        // Fire button input
    input signed [11:0] player_x,       // Player ship X position (center)
    input signed [11:0] hpos,           // Current pixel horizontal position
    input signed [11:0] vpos,           // Current pixel vertical position

    output [7:0] pixel [0:2],            // RGB pixel output
    output active,                      // Bullet is currently being drawn
    output logic signed [11:0] bullet_center_x, // Bullet X position (for collision detection)
    output logic signed [11:0] bullet_top_y      // Bullet Y position (for collision detection)
);

    //-----------------------------------------------------------------------------
    // Internal Registers
    //-----------------------------------------------------------------------------
    reg active_bullet;
    reg signed [11:0] bullet_x, bullet_y;

    reg [0:2] fire_ff;                  // Debounce shift register
    reg fire_latched;                   // Latch to detect single fire press

    //-----------------------------------------------------------------------------
    // Fire Button Debouncing
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            fire_ff <= 3'b000;
            fire_latched <= 1'b0;
        end else begin
            fire_ff <= {fire, fire_ff[0:1]};

            if (~fire_latched && fire_ff[2]) begin
                fire_latched <= 1'b1;
            end

            if (fsync) begin
                fire_latched <= 1'b0; // Clear latch at frame boundary
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Bullet Motion
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            active_bullet <= 1'b0;
            bullet_x <= 0;
            bullet_y <= 0;
        end else if (fsync) begin
            if (active_bullet) begin
                if (bullet_y > BULLET_SPEED) begin
                    bullet_y <= bullet_y - BULLET_SPEED;
                end else begin
                    active_bullet <= 1'b0; // Off screen, deactivate
                end
            end else if (fire_latched) begin
                active_bullet <= 1'b1;
                bullet_x <= player_x;
                bullet_y <= VRES - PADDLE_H - BULLET_H;
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Bullet Center and Top Position Outputs
    //-----------------------------------------------------------------------------
    assign bullet_center_x = bullet_x;
    assign bullet_top_y = bullet_y;

    //-----------------------------------------------------------------------------
    // Bullet Drawing
    //-----------------------------------------------------------------------------
    assign active = active_bullet &&
                    (hpos >= bullet_x - (BULLET_W >> 1)) && (hpos <= bullet_x + (BULLET_W >> 1)) &&
                    (vpos >= bullet_y) && (vpos <= bullet_y + BULLET_H);

    assign pixel[2] = active ? BULLET_COLOR[23:16] : 8'h00;
    assign pixel[1] = active ? BULLET_COLOR[15:8]  : 8'h00;
    assign pixel[0] = active ? BULLET_COLOR[7:0]   : 8'h00;

endmodule
