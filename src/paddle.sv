//-----------------------------------------------------------------------------
// Module: paddle
// Description:
//   - Controls player paddle movement based on button inputs (left, right).
//   - Calculates paddle position each frame.
//   - Outputs RGB pixel data if the current screen position overlaps the paddle.
//-----------------------------------------------------------------------------
import params::*;

module paddle (
    input pixel_clk,
    input rst,
    input fsync,
    input signed [11:0] hpos,
    input signed [11:0] vpos,
    input right,
    input left,
    output [7:0] pixel [0:2],
    output active,
    output logic signed [11:0] paddle_center_x   // <-- NEW!
);

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
    // Paddle Center Calculation
    //-----------------------------------------------------------------------------
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            paddle_center_x <= (HRES >> 1);  // Start centered
        end else if (fsync) begin
            paddle_center_x <= (lhpos + rhpos) >>> 1; // Center = (left + right) / 2
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
