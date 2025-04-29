`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: object
// Description:
//   - Bouncing ball for Pong game.
//   - Updates direction properly at side/top/bottom wall hits.
//   - No getting stuck at walls.
//   - No random initial direction (keeps your original reset behavior).
//////////////////////////////////////////////////////////////////////////////////
import params::*;

module object (
    input pixel_clk,                     // Pixel clock
    input rst,                            // Synchronous reset
    input fsync,                          // Frame sync pulse

    input signed [11:0] hpos,             // Current pixel x position
    input signed [11:0] vpos,             // Current pixel y position

    output [7:0] pixel [0:2],              // Output pixel color (BGR)
    output active                         // High if current pixel overlaps ball
);

    //-----------------------------------------------------------------------------
    // Internal Registers
    //-----------------------------------------------------------------------------
    reg signed [11:0] lhpos, rhpos;         // Horizontal ball bounds
    reg signed [11:0] tvpos, bvpos;         // Vertical ball bounds
    reg [1:0] dir;                          // Current direction

    //-----------------------------------------------------------------------------
    // Direction Update (Wall Bounces)
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk) begin
        if (rst) begin
            dir <= DOWN_RIGHT; // Default start direction
        end else if (fsync) begin
            case (dir)
                DOWN_RIGHT: begin
                    if (bvpos >= VRES - PADDLE_H) begin
                        dir <= UP_RIGHT;
                    end else if (rhpos + OBJECT_VEL >= HRES - 1) begin
                        dir <= DOWN_LEFT;
                    end
                end
                DOWN_LEFT: begin
                    if (bvpos >= VRES - PADDLE_H) begin
                        dir <= UP_LEFT;
                    end else if (lhpos - OBJECT_VEL <= 0) begin
                        dir <= DOWN_RIGHT;
                    end
                end
                UP_RIGHT: begin
                    if (tvpos - OBJECT_VEL <= 0) begin
                        dir <= DOWN_RIGHT;
                    end else if (rhpos + OBJECT_VEL >= HRES - 1) begin
                        dir <= UP_LEFT;
                    end
                end
                UP_LEFT: begin
                    if (tvpos - OBJECT_VEL <= 0) begin
                        dir <= DOWN_LEFT;
                    end else if (lhpos - OBJECT_VEL <= 0) begin
                        dir <= UP_RIGHT;
                    end
                end
            endcase
        end
    end

    //-----------------------------------------------------------------------------
    // Ball Position Update
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk) begin
        if (rst) begin
            lhpos <= (HRES/2) - OBJ_SIZE/2; // Center ball horizontally
            rhpos <= (HRES/2) + OBJ_SIZE/2; 
            tvpos <= (VRES/2) - OBJ_SIZE/2;
            bvpos <= (VRES/2) + OBJ_SIZE/2; 
        end else if (fsync) begin
            case (dir)
                DOWN_RIGHT: begin
                    lhpos <= lhpos + OBJECT_VEL;
                    rhpos <= rhpos + OBJECT_VEL;
                    tvpos <= tvpos + OBJECT_VEL;
                    bvpos <= bvpos + OBJECT_VEL;
                end
                DOWN_LEFT: begin
                    lhpos <= lhpos - OBJECT_VEL;
                    rhpos <= rhpos - OBJECT_VEL;
                    tvpos <= tvpos + OBJECT_VEL;
                    bvpos <= bvpos + OBJECT_VEL;
                end
                UP_RIGHT: begin
                    lhpos <= lhpos + OBJECT_VEL;
                    rhpos <= rhpos + OBJECT_VEL;
                    tvpos <= tvpos - OBJECT_VEL;
                    bvpos <= bvpos - OBJECT_VEL;
                end
                UP_LEFT: begin
                    lhpos <= lhpos - OBJECT_VEL;
                    rhpos <= rhpos - OBJECT_VEL;
                    tvpos <= tvpos - OBJECT_VEL;
                    bvpos <= bvpos - OBJECT_VEL;
                end
            endcase
        end
    end

    //-----------------------------------------------------------------------------
    // Video Output (Ball Drawing)
    //-----------------------------------------------------------------------------
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos) ? 1'b1 : 1'b0;

    assign pixel[2] = (active) ? OBJECT_COLOR[23:16] : 8'h00; // Red
    assign pixel[1] = (active) ? OBJECT_COLOR[15:8]  : 8'h00; // Green
    assign pixel[0] = (active) ? OBJECT_COLOR[7:0]   : 8'h00; // Blue

endmodule
