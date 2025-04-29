`timescale 1ns/1ps
import params::*;

module alien (
    input pixel_clk,
    input rst,
    input fsync,
    input signed [11:0] hpos,
    input signed [11:0] vpos,

    output [7:0] pixel [0:2],
    output active
);

    //-----------------------------------------------------------------------------
    // Internal Position and Motion
    //-----------------------------------------------------------------------------
    reg signed [11:0] lhpos, rhpos; // Left/right x
    reg signed [11:0] tvpos, bvpos; // Top/bottom y

    reg [1:0] dir;                  // 0 = right, 1 = left

    //-----------------------------------------------------------------------------
    // Movement FSM
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            lhpos <= 100;
            rhpos <= 100 + ENEMY_W;
            tvpos <= 100;
            bvpos <= 100 + ENEMY_H;
            dir <= 0;
        end else if (fsync) begin
            if (dir == 0) begin // Moving right
                if (rhpos + ENEMY_SPEED < HRES) begin
                    lhpos <= lhpos + ENEMY_SPEED;
                    rhpos <= rhpos + ENEMY_SPEED;
                end else begin
                    dir <= 1;
                    tvpos <= tvpos + DROP;
                    bvpos <= bvpos + DROP;
                end
            end else begin // Moving left
                if (lhpos - ENEMY_SPEED > 0) begin
                    lhpos <= lhpos - ENEMY_SPEED;
                    rhpos <= rhpos - ENEMY_SPEED;
                end else begin
                    dir <= 0;
                    tvpos <= tvpos + DROP;
                    bvpos <= bvpos + DROP;
                end
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Active Pixel + Color Output
    //-----------------------------------------------------------------------------
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos);

    assign pixel[2] = active ? ENEMY_COLOR[23:16] : 8'h00;
    assign pixel[1] = active ? ENEMY_COLOR[15:8]  : 8'h00;
    assign pixel[0] = active ? ENEMY_COLOR[7:0]   : 8'h00;

endmodule
