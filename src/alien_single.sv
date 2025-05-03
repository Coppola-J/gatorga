//-----------------------------------------------------------------------------
// Module: alien_single
// Description: 
//  This module is used for the single alien generation inside of the 
//  alien_group module. It handles the pixel generation and bounding box, and alive logic. 
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
import params::*;

module alien_single (
    input               pixel_clk,
    input               rst,
    input               fsync,

    input  signed [11:0] hpos,
    input  signed [11:0] vpos,

    input  logic signed [11:0] group_lhpos,
    input  logic signed [11:0] group_tvpos,
    input  logic [3:0]         row,
    input  logic [3:0]         col,

    input  wire               alien_hit,
    input  logic [7:0]         speed,

    output logic [23:0] pixel,
    output active,
    output logic alien_alive,

    output logic signed [11:0] lhpos,
    output logic signed [11:0] rhpos,
    output logic signed [11:0] tvpos,
    output logic signed [11:0] bvpos
);


//-----------------------------------------------------------------------------
// Alive logic
//-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst)
            alien_alive <= 1'b1;
        else if (fsync && alien_hit && alien_alive)
            alien_alive <= 1'b0;
    end

//-----------------------------------------------------------------------------
// Bounding box logic
//-----------------------------------------------------------------------------
    always_comb begin
        lhpos = group_lhpos + col * (ENEMY_W + SPACING_X);
        rhpos = lhpos + ENEMY_W - 1; // Ensure correct width
        tvpos = group_tvpos + row * (ENEMY_H + SPACING_Y);
        bvpos = tvpos + ENEMY_H - 1; // Ensure correct height
    end

//-----------------------------------------------------------------------------
// Pixel generation logic and assignments
//-----------------------------------------------------------------------------
    assign active = (!alien_hit && alien_alive && hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos) ? 1'b1 : 1'b0;
    assign pixel = active ? ENEMY_COLOR : 24'h000000;

endmodule
