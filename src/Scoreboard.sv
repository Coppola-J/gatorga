

module Scoreboard #( 

parameter HRES = 1280,
parameter VRES = 720,
parameter COLOR = 24'h DD4F83
)
    (
        input pixel_clk,
        input rst,
//        input fsync,
        input logic [11:0] hpos, 
        input logic [11:0] vpos, 
        input logic [3:0] player_1_score, 
        input logic [3:0] player_2_score, 
        output logic [7:0] pixel [0:2] , 
        output reg active 
    );
    
    // 3 X 5 pixel for numbers 0 to 9
    localparam unsigned[0:14] numbers[0:9] = '{
        15'b111_101_101_101_111, // 0
        15'b110_010_010_010_111, // 1
        15'b111_001_111_100_111, // 2
        15'b111_001_011_001_111, // 3
        15'b101_101_111_001_001, // 4
        15'b111_100_111_001_111, // 5
        15'b100_100_111_101_111, // 6
        15'b111_001_001_001_001, // 7
        15'b111_101_111_101_111, // 8
        15'b111_101_111_001_001  // 9
        };
        
    logic [3:0] score1, score2 = 0;
    logic location1, location2;
    logic [3:0] number_addr;
    
    always_comb begin
        score1 = (player_1_score < 10) ? player_1_score : 0;
        score2 = (player_2_score < 10) ? player_2_score : 0;
     end
        
     always_comb begin 
        if(hpos >= 10 && hpos < 25 && vpos >= 30 && vpos < 55) begin
            location1 = 1;
            location2 = 0;
        end else if(hpos >= (HRES-25) && hpos < (HRES-10) && vpos >= (VRES-55) && vpos < (VRES-30)) begin
            location1 = 0;
            location2 = 1;
        end else begin
            location1 = 0;
            location2 = 0;
        end
      end
      
      always_comb begin
        if(location1) number_addr = (hpos-10)/5 + ((vpos-30)/5)*3;
        else if(location2) number_addr = (hpos-(HRES-25))/5 + ((vpos-(VRES-55))/5)*3;
        else number_addr = 0;
    end
    
    always_ff @(posedge pixel_clk) begin 
    
//        if(fsync) begin
            if(location1) begin 
                active <= numbers[score1][number_addr];
            end else if(location2) begin 
                active <= numbers[score2][number_addr];
            end else begin 
                active <= 0;
            end
        
//        end
    
    end
    
    
    assign pixel [ 2 ] = (active) ? COLOR [ 23 : 16 ] : 8 'h00; //red 
    assign pixel [ 1 ] = (active) ? COLOR [ 15 : 8 ] : 8 'h00; //green 
    assign pixel [ 0 ] = (active) ? COLOR [ 7 : 0 ] : 8 'h00; //blue 
    
endmodule  