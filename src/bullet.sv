`timescale 1ns/1ps
import params::*;

module bullet (
    input pixel_clk,
    input rst,
    input fsync,
    input fire,                                     // Fire button input
    input signed [11:0] player_x,                   // Player ship X position (center)
    input signed [11:0] hpos,                       // Current pixel horizontal position
    input signed [11:0] vpos,                       // Current pixel vertical position

    output [7:0] pixel [0:2],                       // RGB pixel output                         // Bullet is currently being drawn

    // Collision detection outputs
    output logic bullet_active,                     // Whether bullet is flying
    output logic signed [11:0] bullet_left,
    output logic signed [11:0] bullet_right,
    output logic signed [11:0] bullet_top,
    output logic signed [11:0] bullet_bottom
);

    //-----------------------------------------------------------------------------
    // Internal Registers
    //-----------------------------------------------------------------------------
    reg signed [11:0] bullet_x, bullet_y;
    wire active;                             // Active bullet

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
                fire_latched <= 1'b0; // Clear latch each frame
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Bullet Motion
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            bullet_active <= 1'b0;
            bullet_x <= 0;
            bullet_y <= 0;
        end else if (fsync) begin
            if (bullet_active) begin
                if (bullet_y > BULLET_SPEED) begin
                    bullet_y <= bullet_y - BULLET_SPEED;
                end else begin
                    bullet_active <= 1'b0; // Off screen
                end
            end else if (fire_latched) begin
                bullet_active <= 1'b1;
                bullet_x <= player_x;
                bullet_y <= VRES - PADDLE_H - BULLET_H;
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Bounding Box Output
    //-----------------------------------------------------------------------------
    always_comb begin
        bullet_left   = bullet_x - BULLET_W/2;
        bullet_right  = bullet_x + BULLET_W/2;
        bullet_top    = bullet_y;
        bullet_bottom = bullet_y + BULLET_H;
    end

    //-----------------------------------------------------------------------------
    // Drawing Logic
    //-----------------------------------------------------------------------------
    //assign active = bullet_active && (hpos >= bullet_left) && (hpos <= bullet_right) && (vpos >= bullet_top)  && (vpos <= bullet_bottom);

    assign active = (bullet_active && hpos >= bullet_left && hpos <= bullet_right && vpos >= bullet_top && vpos <= bullet_bottom) ? 1'b1 : 1'b0;

    assign pixel[2] = active ? BULLET_COLOR[23:16] : 8'h00;
    assign pixel[1] = active ? BULLET_COLOR[15:8]  : 8'h00;
    assign pixel[0] = active ? BULLET_COLOR[7:0]   : 8'h00;

endmodule
