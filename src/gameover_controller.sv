module gameover_controller #(
    parameter HRES = 1280,
    parameter VRES = 720,
    parameter PADDLE_H = 20,
    parameter GAMEOVER_H = 200,
    parameter GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1,
    parameter RESTART_PAUSE = 128,
    parameter COLOR_GMO = 24'hDD4F83
)(
    input pixel_clk,
    input rst,
    input fsync,
    input active_obj,
    input active_paddle,
    input signed [11:0] hpos,
    input signed [11:0] vpos,

    output logic game_over,             // Game over active
    output logic use_gameover_pixels,   // Should top use gameover pixels?
    output logic [7:0] pixel_gameover [0:2] // Game over RGB pixels
);

// Internal FSM variables
logic game_over_eval;
logic evaluate;
logic [7:0] pause;
logic active_passing;

// Bitmap ROM signals
wire [HRES-1:0] bitmap;
wire active_gameover;
wire bitmap_on;

//-----------------------------------------------------------------------------
// Game Over Bitmap Memory Instantiation
//-----------------------------------------------------------------------------
gameover_bitmap gameover_bitmap_inst (
    .clka(pixel_clk),
    .ena(1'b1),
    .addra(vpos[7:0]),
    .douta(bitmap)
);

//-----------------------------------------------------------------------------
// Game Over FSM
//-----------------------------------------------------------------------------
always_ff @(posedge pixel_clk) begin
    if (rst) begin
        game_over <= 1'b0;
        game_over_eval <= 1'b0;
        evaluate <= 1'b0;
        pause <= 0;
        active_passing <= 1'b0;
    end else begin
        if (~evaluate) begin
            if (fsync) begin
                evaluate <= 1'b1;
            end
            pause <= 0;
            active_passing <= 1'b0;
        end else begin
            if (~game_over_eval) begin
                if (vpos == VRES - PADDLE_H && active_obj) begin
                    active_passing <= 1'b1;
                    if (active_paddle) begin
                        evaluate <= 1'b0;
                    end
                end else if (active_passing) begin
                    if (~active_obj) begin
                        game_over_eval <= 1'b1;
                    end
                end
            end else if (fsync) begin
                if (pause == RESTART_PAUSE) begin
                    game_over_eval <= 1'b0;
                    evaluate <= 1'b0;
                    game_over <= 1'b0;
                end else begin
                    pause <= pause + 1;
                    game_over <= 1'b1;
                end
            end
        end
    end
end

//-----------------------------------------------------------------------------
// Game Over Pixel Coloring
//-----------------------------------------------------------------------------

assign active_gameover = (game_over && vpos >= GAMEOVER_VSTART && vpos < GAMEOVER_VSTART + GAMEOVER_H);
assign bitmap_on = (bitmap >> hpos) & 1'b1;

// Set RGB based on bitmap pixel
assign pixel_gameover[2] = (active_gameover && bitmap_on) ? COLOR_GMO[23:16] : 8'h00; // Red
assign pixel_gameover[1] = (active_gameover && bitmap_on) ? COLOR_GMO[15:8]  : 8'h00; // Green
assign pixel_gameover[0] = (active_gameover && bitmap_on) ? COLOR_GMO[7:0]   : 8'h00; // Blue

// Decide whether gameover pixels should override normal display
assign use_gameover_pixels = game_over;

endmodule
