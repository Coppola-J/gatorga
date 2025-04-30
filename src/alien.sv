`timescale 1ns/1ps
import params::*;

module alien (
    input pixel_clk,
    input rst,
    input fsync,

    input signed [11:0] hpos,
    input signed [11:0] vpos,

    input alien_hit_external,     // <-- NEW: Comes from external collision detector

    output [7:0] pixel [0:2],
    output active,
    output logic alien_alive,           // Still needed by collision module
    output logic signed [11:0] lhpos,   // Bounding box output
    output logic signed [11:0] rhpos,
    output logic signed [11:0] tvpos,
    output logic signed [11:0] bvpos
);

    // Internal direction state
    logic [1:0] dir;

    //-----------------------------------------------------------------------------
    // Alien Position & Movement
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            lhpos <= 100;
            rhpos <= 100 + ENEMY_W;
            tvpos <= 100;
            bvpos <= 100 + ENEMY_H;
            dir <= 0;
            alien_alive <= 1'b1;
        end else if (fsync) begin
            // Mark dead if hit this frame
            if (alien_hit_external && alien_alive)
                alien_alive <= 1'b0;

            if (alien_alive) begin
                // Move horizontally, switch direction and drop if needed
                if (dir == 0) begin
                    if (rhpos + ENEMY_SPEED < HRES) begin
                        lhpos <= lhpos + ENEMY_SPEED;
                        rhpos <= rhpos + ENEMY_SPEED;
                    end else begin
                        dir <= 1;
                        tvpos <= tvpos + DROP;
                        bvpos <= bvpos + DROP;
                    end
                end else begin
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
    end

    //-----------------------------------------------------------------------------
    // Pixel Drawing
    //-----------------------------------------------------------------------------
    assign active = (alien_alive && hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos) ? 1'b1 : 1'b0;

    assign pixel[2] = active ? ENEMY_COLOR[23:16] : 8'h00;
    assign pixel[1] = active ? ENEMY_COLOR[15:8]  : 8'h00;
    assign pixel[0] = active ? ENEMY_COLOR[7:0]   : 8'h00;

endmodule
