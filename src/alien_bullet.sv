`timescale 1ns/1ps
import params::*;

module alien_bullet (
    input pixel_clk,
    input rst,
    input fsync,
    input logic fire,                    // fire signal from alien group
    input logic [11:0] alien_x,          // chosen alien x
    input logic [11:0] alien_y,          // chosen alien y

    input signed [11:0] hpos,
    input signed [11:0] vpos,

    output [7:0] pixel [0:2],
    output logic bullet_active
);


    reg signed [11:0] bullet_left, bullet_right, bullet_top, bullet_bottom;
    reg signed [11:0] bullet_x, bullet_y;
    wire active;

    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            bullet_active <= 0;
            bullet_x <= '0;
            bullet_y <= '0;
        end else if (fsync) begin
            if (bullet_active) begin
                if (bullet_y < VRES - ENEMY_BULLET_SPEED)
                    bullet_y <= bullet_y + ENEMY_BULLET_SPEED; // move down
                else
                    bullet_active <= 0;
            end else if (fire) begin
                bullet_active <= 1'b1;
                bullet_x <= alien_x;
                bullet_y <= alien_y;
            end
        end
    end

    always_comb begin
        bullet_left   = (rst) ? 0 : bullet_x - BULLET_W/2;
        bullet_right  = (rst) ? 0 : bullet_x + BULLET_W/2;
        bullet_top    = (rst) ? 0 : bullet_y;
        bullet_bottom = (rst) ? 0 : bullet_y + BULLET_H;
    end

    assign active = (bullet_active && hpos >= bullet_left && hpos <= bullet_right && vpos >= bullet_top && vpos <= bullet_bottom) ? 1'b1 : 1'b0;

    // Output paddle color if active, otherwise black
    assign pixel[2] = (active) ? PADDLE_COLOR[23:16] : 8'h00; // Red channel
    assign pixel[1] = (active) ? PADDLE_COLOR[15:8]  : 8'h00; // Green channel
    assign pixel[0] = (active) ? PADDLE_COLOR[7:0]   : 8'h00; // Blue channel

endmodule
