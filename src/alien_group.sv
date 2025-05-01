`timescale 1ns/1ps
import params::*;

module alien_group #(
    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 5
)(
    input                pixel_clk,
    input               rst,
    input                fsync,

    input  signed [11:0] hpos,
    input  signed [11:0] vpos,

    input  logic [7:0]         speed,
    input  logic               bullet_active,
    input  signed [11:0] bullet_left,
    input  signed [11:0] bullet_right,
    input  signed [11:0] bullet_top,
    input  signed [11:0] bullet_bottom,

    output wire               alien_hit_out,
    output logic [$clog2(NUM_ROWS * NUM_COLS + 1)-1:0] aliens_remaining,
    output logic [7:0] pixel [0:2],
    output                active
);

    // Group position
    logic signed [11:0] group_lhpos, group_tvpos;
    logic               dir;
    logic [7:0] alien_pixel [0:2];

    // Width of full alien group
    localparam TOTAL_W = NUM_COLS * ENEMY_W + (NUM_COLS - 1) * SPACING_X;

    // Group movement
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            group_lhpos <= ALIEN_START;
            group_tvpos <= ALIEN_START;
            dir <= 0;
        end else if (fsync) begin
            if (dir == 0) begin
                if (group_lhpos + TOTAL_W + speed < HRES)
                    group_lhpos <= group_lhpos + speed;
                else begin
                    dir <= 1;
                    group_tvpos <= group_tvpos + DROP;
                end
            end else begin
                if (group_lhpos > speed)
                    group_lhpos <= group_lhpos - speed;
                else begin
                    dir <= 0;
                    group_tvpos <= group_tvpos + DROP;
                end
            end
        end
    end

    // Alien wires
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] alien_hit_array;
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] alien_alive;
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] actives;
    logic [7:0] blue_pixels [NUM_ROWS-1:0][NUM_COLS-1:0];  // Blue channel
    logic [7:0] green_pixels [NUM_ROWS-1:0][NUM_COLS-1:0]; // Green channel
    logic [7:0] red_pixels [NUM_ROWS-1:0][NUM_COLS-1:0];
    logic [NUM_ROWS-1:0][NUM_COLS-1:0][11:0] lhpos, rhpos, tvpos, bvpos;

    assign active = |actives; // Reduction OR to check if any alien is active

    always_comb begin
        // Initialize the pixel output to black (no color)
        alien_pixel[0] = 8'h00; // Blue channel
        alien_pixel[1] = 8'h00; // Green channel
        alien_pixel[2] = 8'h00; // Red channel

        // Iterate through all aliens and OR their pixel outputs
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                alien_pixel[0] |= blue_pixels[r][c];  // Combine Blue channel
                alien_pixel[1] |= green_pixels[r][c]; // Combine Green channel
                alien_pixel[2] |= red_pixels[r][c];   // Combine Red channel
            end
        end
    end

    assign pixel = alien_pixel;

    // Track how many aliens are alive
    always_comb begin
        aliens_remaining = 0;
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                if (alien_alive[r][c])
                    aliens_remaining++;
            end
        end
    end

    assign alien_hit_out = |alien_hit_array; // Combine all alien hits into a single signal

    // Instantiate all aliens and their collision detectors
generate
    genvar r, c; // Declare r and c as genvar
    for (r = 0; r < NUM_ROWS; r++) begin : row_loop
        for (c = 0; c < NUM_COLS; c++) begin : col_loop

            alien_single alien_inst (
                .pixel_clk(pixel_clk),
                .rst(rst),
                .fsync(fsync),
                .hpos(hpos),
                .vpos(vpos),
                .group_lhpos(group_lhpos),
                .group_tvpos(group_tvpos),
                .row(r),
                .col(c),
                .speed(speed),
                .alien_hit(alien_hit_array[r][c]),
                .pixel({red_pixels[r][c], green_pixels[r][c], blue_pixels[r][c]}), // Pass RGB channels
                .active(actives[r][c]),
                .alien_alive(alien_alive[r][c]),
                .lhpos(lhpos[r][c]),
                .rhpos(rhpos[r][c]),
                .tvpos(tvpos[r][c]),
                .bvpos(bvpos[r][c])
            );

            collision_controller coll_inst (
                .pixel_clk(pixel_clk),
                .rst(rst),
                .fsync(fsync),
                .bullet_active(bullet_active),
                .alien_alive(alien_alive[r][c]),
                .bullet_left(bullet_left),
                .bullet_right(bullet_right),
                .bullet_top(bullet_top),
                .bullet_bottom(bullet_bottom),
                .alien_lhpos(lhpos[r][c]),
                .alien_rhpos(rhpos[r][c]),
                .alien_tvpos(tvpos[r][c]),
                .alien_bvpos(bvpos[r][c]),
                .alien_hit(alien_hit_array[r][c])
            );
        end
    end
endgenerate

endmodule
