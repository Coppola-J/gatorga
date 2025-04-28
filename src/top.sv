module top 
( 
    input clk125, 
    input p1_right,
    input p1_left, 
    input p2_right,
    input p2_left,

	//input rand_dir_in,
	output rst_trig,        // add a driver to reset (switch) for user control
    
    output tmds_tx_clk_p, 
    output tmds_tx_clk_n,
	
    output [2:0] tmds_tx_data_p, 
    output [2:0] tmds_tx_data_n,
    output led_kawser 

    /*      Debug
    output [ 11 : 0 ] lhpos_out_bot, 
	output [ 11 : 0 ] rhpos_out_bot, 
	output [ 11 : 0 ] tvpos_out_bot,
	output [ 11 : 0 ] bvpos_out_bot,
	
	output [11:0] hpos_out,
	output [11:0] vpos_out,
    */
); 
	
    
localparam HRES = 1280; 
localparam VRES = 720; 

localparam PADDLE_W = 200;
localparam PADDLE_H = 20; 

localparam COLOR_OBJ = 24'h 00FF90; 
localparam COLOR_PAD = 24'h EFE62E; 
localparam COLOR_GMO = 24'h DD4F83; 

localparam GAMEOVER_H = 200; 
localparam GAMEOVER_VSTART = (VRES - GAMEOVER_H) >> 1 ; 
localparam RESTART_PAUSE = 128 ;

wire pixel_clk; 
wire rst; 
wire active ; 
wire fsync; 

wire signed [11:0] hpos; 
wire signed [11:0] vpos; 

wire [7:0] pixel [0:2] ; 

wire active_obj ; 
reg active_passing ; 

wire [7:0] pixel_obj [0:2];
wire active_paddle_top;
wire active_paddle_bot; 
wire [7 : 0 ] pixel_paddle_top [0:2] ;
wire [7 : 0 ] pixel_paddle_bot [0:2] ;

reg game_over_eval, evaluate ; 
reg game_over; 

reg [7 : 0 ] pause ; 
wire [HRES-1 : 0] bitmap ; 

wire active_gameover ; 
wire bitmap_on; 
wire [7:0] pixel_gameover [0:2] ; 

wire active_scoreboard;
wire [7:0] pixel_scoreboard [0:2];
reg [3:0] player1_score = 0;
reg [3:0] player2_score = 0;

reg player1_just_scored, player2_just_scored; 


Scoreboard #( 
    .HRES      (HRES),
    .VRES      (VRES),
    .COLOR     (COLOR_GMO)
)
Scoreboard_inst
(
    .pixel_clk       (pixel_clk),
    .rst             (rst),
    .hpos            (hpos), 
    .vpos            (vpos),  
    .player_1_score  (player1_score), 
    .player_2_score  (player2_score), 
    .pixel           (pixel_scoreboard) , 
    .active          (active_scoreboard)
);



// HDMIT Transmit + clock video timing 
hdmi_transmit hdmi_transmit_inst ( 
    .clk125         (clk125), 
    .pixel          (pixel), 
    // Shared video interface to the rest of the system 
    .pixel_clk      (pixel_clk), 
    .rst            (rst),
    .active         (active),
    .fsync          (fsync),
    .hpos           (hpos),
    .vpos           (vpos), 
    .tmds_tx_clk_p  (tmds_tx_clk_p),  
    .tmds_tx_clk_n  (tmds_tx_clk_n),
    .tmds_tx_data_p (tmds_tx_data_p), 
    .tmds_tx_data_n (tmds_tx_data_n)
); 
     
// Handle Bounce 
object #( 
    .HRES      (HRES),
    .VRES      (VRES),
    .COLOR     (COLOR_OBJ),
    .PADDLE_H  (PADDLE_H) 
) object_inst
(
    .pixel_clk   (pixel_clk),
    .rst         (rst || game_over),
    .fsync       (fsync),  
    .hpos        (hpos), 
    .vpos        (vpos), 
    .pixel       (pixel_obj) ,
    //.rand_dir	(rand_dir_in),
    .active      (active_obj)       
);
     
// Top paddle
paddle #( 
    .HRES      (HRES),
    .VRES      (VRES),
    .PADDLE_POS (20),
    .PADDLE_W  (PADDLE_W),
    .PADDLE_H  (PADDLE_H),
    .COLOR     (COLOR_PAD)
) paddle_top_inst
(
    .pixel_clk   (pixel_clk),
    .rst         (rst || game_over),
    .fsync       (fsync),  
    .hpos        (hpos), 
    .vpos        (vpos), 
    .right       (p1_right),
    .left        (p1_left), 
    .pixel       (pixel_paddle_top) , 
    .active      (active_paddle_top)       
);

// Bottom paddle 
paddle #( 
    .HRES      (HRES),
    .VRES      (VRES),
    .PADDLE_POS (720),
    .PADDLE_W  (PADDLE_W),
    .PADDLE_H  (PADDLE_H),
    .COLOR     (COLOR_PAD)
) paddle_bot_inst
(
    .pixel_clk   (pixel_clk),
    .rst         (rst || game_over),
    .fsync       (fsync),  
    .hpos        (hpos), 
    .vpos        (vpos), /* Debug
    .lhpos_out	(lhpos_out_bot), 
    .rhpos_out	(rhpos_out_bot), 
    .tvpos_out	(tvpos_out_bot), 
    .bvpos_out	(bvpos_out_bot),	*/   
    .right       (p2_right),
    .left        (p2_left),        
    .pixel       (pixel_paddle_bot) , 
    .active      (active_paddle_bot)
);

gameover_bitmap gameover_bitmap_inst ( 
    .clka           (pixel_clk),
    .ena            (1'b1),
    .addra          (vpos [7:0]),
    .douta          (bitmap)
); 
       
       
    
// GAME OVER Pixel active, middle of the screen 
assign active_gameover = (game_over && vpos >= GAMEOVER_VSTART  && vpos < GAMEOVER_VSTART + GAMEOVER_H)  ? 1'b1 : 1'b0 ; 

assign bitmap_on = (bitmap >> hpos) & 1'b1; 

// RGB pixels for pop up game 
assign pixel_gameover [2] = (active_gameover && bitmap_on) ? COLOR_GMO [23 : 16] : 8'h00; 
assign pixel_gameover [1] = (active_gameover && bitmap_on) ? COLOR_GMO [15 : 8] : 8'h00; 
assign pixel_gameover [0] = (active_gameover && bitmap_on) ? COLOR_GMO [7 : 0] : 8'h00; 


// Display RGB pixels 

assign pixel [2] = game_over ? pixel_gameover [2] : pixel_obj [ 2 ] | pixel_paddle_top [ 2 ] | pixel_paddle_bot[2] | pixel_scoreboard[2];
assign pixel [1] = game_over ? pixel_gameover [1] : pixel_obj [ 1 ] | pixel_paddle_top [ 1 ] | pixel_paddle_bot[1] | pixel_scoreboard[1];
assign pixel [0] = game_over ? pixel_gameover [0] : pixel_obj [ 0 ] | pixel_paddle_top [ 0 ] | pixel_paddle_bot[0] | pixel_scoreboard[0];
       
assign led_kawser = 1; 
assign rst_trig   = rst;
assign hpos_out   = hpos;
assign vpos_out   = vpos;


// We need to detect gameover 
always @(posedge pixel_clk) begin              
    if(rst) begin 
        game_over               <= 1'b0; 
        game_over_eval          <= 1'b0; 
        evaluate                <= 1'b0;
        pause                   <= 0;
        active_passing          <= 1'b0; 
        player1_just_scored     <= 1'b0;
        player2_just_scored     <= 1'b0;
    end else begin
        if(~evaluate) begin 
            if (fsync) begin 
                evaluate <= 1'b1; 
            end
        pause                   <= 0;
        active_passing          <= 1'b0; 
        player1_just_scored     <= 1'b0;
        player2_just_scored     <= 1'b0;
        end else begin 
            if(~game_over_eval) begin 
                if(vpos == VRES - PADDLE_H && active_obj) begin 
                    active_passing          <= 1'b1; 
                    player1_just_scored     <= 1'b1;
                        if (active_paddle_bot) begin 
                            evaluate        <= 1'b0;
                        end
                end else if(vpos == PADDLE_H && active_obj) begin 
                        active_passing          <= 1'b1; 
                        player2_just_scored     <= 1'b1;
                            if (active_paddle_top) begin 
                                evaluate                <= 1'b0;
                            end
                end else if (active_passing) begin 
                    if(~active_obj) begin 
                            game_over_eval          <= 1'b1; 
                    end
                end
            end else if (fsync) begin 
                if(pause == RESTART_PAUSE) begin
                    game_over_eval          <= 1'b0;
                    evaluate                <= 1'b0; 
                    game_over               <= 1'b0; 
                    if(player1_just_scored) begin
                        if(player1_score == 9) begin
                            player1_score <= 0;
                            player2_score <= 0;
                        end else begin 
                            player1_score <= player1_score + 1;
                        end;
                    end else begin
                        if(player2_score == 9) begin
                            player1_score <= 0;
                            player2_score <= 0;
                        end else begin 
                            player2_score <= player2_score + 1;
                        end
                    end
                end else begin 
                    pause                   <= pause + 1; 
                    game_over               <= 1'b1; 
                end
            end
        end 
    end 
end 

endmodule 
