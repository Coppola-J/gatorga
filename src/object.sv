`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: object
// Description:
//   - Bouncing ball for Pong game.
//   - Updates direction properly at side/top/bottom wall hits.
//   - No getting stuck at walls.
//   - No random initial direction (keeps your original reset behavior).
//////////////////////////////////////////////////////////////////////////////////

module object #(
    parameter HRES = 1280,               // Horizontal resolution
    parameter VRES = 720,                // Vertical resolution
    parameter COLOR = 24'h00FF90,         // Object color (neon green)
    parameter PADDLE_H = 20               // Paddle height (bottom zone to avoid)
)(
    input pixel_clk,                     // Pixel clock
    input rst,                            // Synchronous reset
    input fsync,                          // Frame sync pulse

    input signed [11:0] hpos,             // Current pixel x position
    input signed [11:0] vpos,             // Current pixel y position

    output [7:0] pixel [0:2],              // Output pixel color (BGR)
    output active                         // High if current pixel overlaps ball
);

    //-----------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------
    localparam OBJ_SIZE = 50;              // Ball size
    localparam [1:0] DOWN_RIGHT = 2'b00;   // Moving down and right
    localparam [1:0] DOWN_LEFT  = 2'b01;   // Moving down and left
    localparam [1:0] UP_RIGHT   = 2'b10;   // Moving up and right
    localparam [1:0] UP_LEFT    = 2'b11;   // Moving up and left

    localparam VEL = 6;                  // Ball velocity (pixels/frame)

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
                    end else if (rhpos + VEL >= HRES - 1) begin
                        dir <= DOWN_LEFT;
                    end
                end
                DOWN_LEFT: begin
                    if (bvpos >= VRES - PADDLE_H) begin
                        dir <= UP_LEFT;
                    end else if (lhpos - VEL <= 0) begin
                        dir <= DOWN_RIGHT;
                    end
                end
                UP_RIGHT: begin
                    if (tvpos - VEL <= 0) begin
                        dir <= DOWN_RIGHT;
                    end else if (rhpos + VEL >= HRES - 1) begin
                        dir <= UP_LEFT;
                    end
                end
                UP_LEFT: begin
                    if (tvpos - VEL <= 0) begin
                        dir <= DOWN_LEFT;
                    end else if (lhpos - VEL <= 0) begin
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
                    lhpos <= lhpos + VEL;
                    rhpos <= rhpos + VEL;
                    tvpos <= tvpos + VEL;
                    bvpos <= bvpos + VEL;
                end
                DOWN_LEFT: begin
                    lhpos <= lhpos - VEL;
                    rhpos <= rhpos - VEL;
                    tvpos <= tvpos + VEL;
                    bvpos <= bvpos + VEL;
                end
                UP_RIGHT: begin
                    lhpos <= lhpos + VEL;
                    rhpos <= rhpos + VEL;
                    tvpos <= tvpos - VEL;
                    bvpos <= bvpos - VEL;
                end
                UP_LEFT: begin
                    lhpos <= lhpos - VEL;
                    rhpos <= rhpos - VEL;
                    tvpos <= tvpos - VEL;
                    bvpos <= bvpos - VEL;
                end
            endcase
        end
    end

    //-----------------------------------------------------------------------------
    // Video Output (Ball Drawing)
    //-----------------------------------------------------------------------------
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos) ? 1'b1 : 1'b0;

    assign pixel[2] = (active) ? COLOR[23:16] : 8'h00; // Red
    assign pixel[1] = (active) ? COLOR[15:8]  : 8'h00; // Green
    assign pixel[0] = (active) ? COLOR[7:0]   : 8'h00; // Blue

endmodule
