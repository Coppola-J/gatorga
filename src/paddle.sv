//-----------------------------------------------------------------------------
// Module: paddle
// Description:
//   - Controls player paddle movement based on button inputs (left, right).
//   - Calculates paddle position each frame.
//   - Outputs RGB pixel data if the current screen position overlaps the paddle.
//-----------------------------------------------------------------------------
import params::*;

module paddle (
    input pixel_clk,                   // Pixel clock
    input rst,                         // Synchronous reset
    input fsync,                       // Frame sync (start of new frame)

    input signed [11:0] hpos,           // Current pixel x-coordinate
    input signed [11:0] vpos,           // Current pixel y-coordinate

    input right,                       // Right button input
    input left,                        // Left button input

    output [7:0] pixel [0:2],           // Output pixel color (BGR order)
    output active                      // High when current pixel overlaps paddle
);

    //-----------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------
    localparam PADDLE_VEL = 16;                // Paddle PADDLE_VELocity per frame (in pixels)

    localparam PUT = 2'h0;              // Paddle idle (no movement)
    localparam LEFT = 2'h1;             // Move left
    localparam RIGHT = 2'h2;            // Move right

    //-----------------------------------------------------------------------------
    // Internal Signals
    //-----------------------------------------------------------------------------
    reg [0:2] right_ff, left_ff;         // Button debounce shift registers

    reg signed [11:0] lhpos;             // Left x-boundary of paddle
    reg signed [11:0] rhpos;             // Right x-boundary of paddle
    reg signed [11:0] tvpos;             // Top y-boundary of paddle
    reg signed [11:0] bvpos;             // Bottom y-boundary of paddle

    reg [1:0] dir;                       // Current paddle movement direction
    reg register_right, register_left;   // Latches for right/left button events

    //-----------------------------------------------------------------------------
    // Paddle Movement Direction Control
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk) begin
        if (rst) begin
            dir <= PUT;
            register_right <= 1'b0;
            register_left <= 1'b0;
        end else begin
            if (fsync) begin
                // Update direction on frame sync
                if (register_right) begin
                    dir <= RIGHT;
                end else if (register_left) begin
                    dir <= LEFT;
                end else begin
                    dir <= PUT;
                end
                // Clear registers for next frame
                register_right <= 1'b0;
                register_left <= 1'b0;
            end else begin
                // Capture button presses during the frame
                if (~register_right && ~register_left) begin
                    if (right_ff[2]) begin
                        register_right <= 1'b1;
                    end else if (left_ff[2]) begin
                        register_left <= 1'b1;
                    end
                end
            end
        end

        // Debounce button inputs
        right_ff <= {right, right_ff[0:1]};
        left_ff <= {left, left_ff[0:1]};
    end

    //-----------------------------------------------------------------------------
    // Paddle Position Update
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk) begin
        if (rst) begin
            // Center paddle at start
            lhpos <= (HRES - PADDLE_W) >> 1;
            rhpos <= (HRES + PADDLE_W) >> 1;
            tvpos <= VRES - PADDLE_H;     // Near bottom of screen
            bvpos <= VRES - 1;
        end else begin
            if (fsync) begin
                // Move paddle based on direction
                if (dir == RIGHT && rhpos + PADDLE_VEL < HRES) begin // Right movement and if the poostion of the paddle after moving is within the screen
                    lhpos <= lhpos + PADDLE_VEL;
                    rhpos <= rhpos + PADDLE_VEL;
                end else if (dir == LEFT && lhpos - PADDLE_VEL > 0) begin
                    lhpos <= lhpos - PADDLE_VEL;
                    rhpos <= rhpos - PADDLE_VEL;
                end
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Video Output (Active Pixel Detection + Coloring)
    //-----------------------------------------------------------------------------

    // Active if current pixel is inside paddle bounds
    assign active = (hpos >= lhpos && hpos <= rhpos && vpos >= tvpos && vpos <= bvpos) ? 1'b1 : 1'b0;

    // Output paddle color if active, otherwise black
    assign pixel[2] = (active) ? PADDLE_COLOR[23:16] : 8'h00; // Red channel
    assign pixel[1] = (active) ? PADDLE_COLOR[15:8]  : 8'h00; // Green channel
    assign pixel[0] = (active) ? PADDLE_COLOR[7:0]   : 8'h00; // Blue channel

endmodule
