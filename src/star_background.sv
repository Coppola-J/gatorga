//-----------------------------------------------------------------------------
// Module: star_background
// Description: 
//  Used to add a star background to the game. Stars are randomly generated and move down the screen.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps
import params::*;

module star_background #(
    parameter STAR_COUNT = 64
)(
    input  logic        pixel_clk,
    input  logic        rst,
    input  logic        fsync,
    input  logic signed [11:0] hpos,
    input  logic signed [11:0] vpos,
    input  logic [1:0]  game_state,

    output logic [7:0]  pixel [0:2],
    output logic        active
);

    typedef struct packed {
        logic signed [11:0] x;
        logic signed [11:0] y;
        logic [7:0] r, g, b;
        logic [1:0] speed; // 1 to 3
    } star_t;

    star_t stars [STAR_COUNT];

    // Random generator
    logic [15:0] rnd;
    lfsr rand_gen (
        .clk(pixel_clk),
        .rst(rst),
        .rnd(rnd)
    );

    logic [7:0] star_init_index;
    logic       stars_initialized;

    // Star initialization and movement
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            star_init_index <= 0;
            stars_initialized <= 0;
        end else if (!stars_initialized) begin
            stars[star_init_index].x <= rnd[11:0] % PLAYABLE_AREA_H;
            stars[star_init_index].y <= rnd[11:0] % PLAYABLE_AREA_V;

            stars[star_init_index].r <= {rnd[7:5], 5'b0};
            stars[star_init_index].g <= {rnd[10:8], 5'b0};
            stars[star_init_index].b <= {rnd[4:2], 5'b0};
            stars[star_init_index].speed <= (rnd[1:0] % 3) + 1;

            if (star_init_index == STAR_COUNT - 1)
                stars_initialized <= 1;
            else
                star_init_index <= star_init_index + 1;
        end else if (fsync) begin
            for (int i = 0; i < STAR_COUNT; i++) begin
                if (stars[i].y <= stars[i].speed)
                    stars[i].y <= PLAYABLE_AREA_V - 1;
                else
                    stars[i].y <= stars[i].y - stars[i].speed;
            end
        end
    end

    // Pixel rendering
    always_comb begin
        active = 0;
        pixel[0] = 8'h00;
        pixel[1] = 8'h00;
        pixel[2] = 8'h00;

        for (int i = 0; i < STAR_COUNT; i++) begin
            if (hpos == stars[i].x && vpos == stars[i].y) begin
                active = 1;
                pixel[0] = stars[i].b;
                pixel[1] = stars[i].g;
                pixel[2] = stars[i].r;
            end
        end
    end

endmodule


/*
    // Active signal for star background
    always_comb begin
        active = 0;
        for (int i = 0; i < STAR_COUNT; i++) begin
            if (hpos == stars[i].x && vpos == stars[i].y) begin
                active = 1;
            end
        end
    end

    assign pixel[2] = active ? BULLET_COLOR[23:16] : 8'h00;
    assign pixel[1] = active ? BULLET_COLOR[15:8]  : 8'h00;
    assign pixel[0] = active ? BULLET_COLOR[7:0]   : 8'h00;

endmodule
*/