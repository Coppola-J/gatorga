`timescale 1ns/1ps
import params::*;

module alien_group (
    input                pixel_clk,
    input                rst,
    input                fsync,

    input  signed [11:0] hpos,
    input  signed [11:0] vpos,

    input  logic [7:0]         speed,

    input  logic       bullet_active,
    input  signed [11:0] bullet_left,
    input  signed [11:0] bullet_right,
    input  signed [11:0] bullet_top,
    input  signed [11:0] bullet_bottom,

    input signed [11:0] paddle_left,
    input signed [11:0] paddle_right,
    input signed [11:0] paddle_top,
    input signed [11:0] paddle_bottom,
    output logic alien_reached_paddle,  // NEW OUTPUT

    output wire         alien_hit_out,
    output logic [$clog2(NUM_ROWS * NUM_COLS + 1)-1:0] aliens_remaining,
    output logic [7:0] pixel [0:2],
    output                active,


    // Debug
    output logic signed [11:0] alien_bullet_x,
    output logic signed [11:0] alien_bullet_y
);

    // Group position
    logic signed [11:0] group_lhpos, group_tvpos;
    logic               dir;
    logic [7:0] alien_pixel [0:2];

    // Width of full alien group
    localparam TOTAL_W = NUM_COLS * ENEMY_W + (NUM_COLS - 1) * SPACING_X;


    logic signed [11:0] row_lhpos [NUM_ROWS-1:0];  // Per-row left pos
    logic row_dir [NUM_ROWS-1:0];                  // 0 = right, 1 = left
    logic signed [11:0] group_tvpos;               // Shared vertical top position
    logic drop_flag;                               // Flag to indicate group drop

    // Group movement
    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            for (int r = 0; r < NUM_ROWS; r++) begin
                row_lhpos[r] <= ALIEN_HSTART;
                row_dir[r] <= (r % 2);  // Alternate direction
            end
            group_tvpos <= ALIEN_VSTART;
        end else if (fsync) begin
            drop_flag <= 0;
                for (int r = 0; r < NUM_ROWS; r++) begin
                    // Predict next position
                    logic signed [11:0] next_lhpos = row_lhpos[r] + (row_dir[r] ? -speed : speed);

                    // Compute left/right edges at next position
                    logic signed [11:0] next_left_edge  = next_lhpos + leftmost_col[r]  * (ENEMY_W + SPACING_X);
                    logic signed [11:0] next_right_edge = next_lhpos + rightmost_col[r] * (ENEMY_W + SPACING_X) + ENEMY_W;

                    // Check bounds
                    logic will_hit_left  = (next_left_edge <= speed);
                    logic will_hit_right = (next_right_edge >= HRES);

                    if ((row_dir[r] && will_hit_left) || (!row_dir[r] && will_hit_right)) begin
                        // Change direction and mark drop
                        row_dir[r] <= ~row_dir[r];
                        drop_flag <= 1;
                    end else begin
                        // Safe to move, update position
                        row_lhpos[r] <= next_lhpos;
                    end
                end
            if (drop_flag)
                group_tvpos <= group_tvpos + DROP;
        end
    end



    // Alien wires
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] alien_hit_array;
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] alien_alive;
    logic [NUM_ROWS-1:0][NUM_COLS-1:0] actives;
    logic [7:0] blue_pixels [NUM_ROWS-1:0][NUM_COLS-1:0];
    logic [7:0] green_pixels [NUM_ROWS-1:0][NUM_COLS-1:0];
    logic [7:0] red_pixels [NUM_ROWS-1:0][NUM_COLS-1:0];
    logic signed [NUM_ROWS-1:0][NUM_COLS-1:0][11:0] lhpos, rhpos, tvpos, bvpos;

    // Alien bullet wires
    logic [7:0] alien_bullet_pixel [0:2];
    logic alien_bullet_active;
    logic fire_alien_bullet;
    logic [3:0] fire_row, fire_col;
    logic signed [11:0] fire_x, fire_y;

    assign active = |actives;

//-----------------------------------------------------------------------------
// Random alien bullet firing logic using LFSR-based randomness
//-----------------------------------------------------------------------------

// 16-bit Linear Feedback Shift Register for randomness
logic [15:0] rnd;
lfsr rand_gen (
    .clk(pixel_clk),   // Use the pixel clock for updates
    .rst(rst),         // Reset signal to initialize the LFSR
    .rnd(rnd)          // Output pseudo-random value
);

// Fire a bullet if specific LFSR bits match (1 in 8 chance)
// You can tweak the bits and pattern to change firing frequency
assign fire_alien_bullet = (rnd[6:4] == 4'b101);

// Index for sequential firing
logic [$clog2(NUM_ROWS * NUM_COLS):0] seq_index;
logic [$clog2(NUM_ROWS * NUM_COLS):0] seq_counter;

always_comb begin
    // Randomly select a row and column using LFSR bits
    fire_row = rnd[7:4] % NUM_ROWS;     // 4 bits → range 0 to 15 → modulo limits it to NUM_ROWS
    fire_col = rnd[11:8] % NUM_COLS;    // 4 bits → range 0 to 15 → modulo limits it to NUM_COLS

    // If randomly selected alien is not alive, fallback to first alive alien
    if (aliens_remaining <= (NUM_ROWS * NUM_COLS)/2) begin
        if (!alien_alive[fire_row][fire_col]) begin
            for (int r = 0; r < NUM_ROWS; r++) begin
                for (int c = 0; c < NUM_COLS; c++) begin
                    if (alien_alive[r][c]) begin
                        fire_row = r;
                        fire_col = c;
                        break;
                    end
                end
            end
        end
    end else begin
        if (!alien_alive[fire_row][fire_col]) begin
        // fallback scan (first alive alien)
            for (int r = 0; r < NUM_ROWS; r++) begin
                for (int c = 0; c < NUM_COLS; c++) begin
                    if (alien_alive[r][c]) begin
                        fire_row = r;
                        fire_col = c;
                        break;
                    end
                end
            end
        end
    end 
    // Determine bullet spawn coordinates (center bottom of selected alien)
    fire_x = lhpos[fire_row][fire_col] + ENEMY_W / 2; // Horizontal center
    fire_y = bvpos[fire_row][fire_col];               // Bottom edge
end


    always_comb begin
        alien_pixel[0] = 8'h00;
        alien_pixel[1] = 8'h00;
        alien_pixel[2] = 8'h00;
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                alien_pixel[0] |= blue_pixels[r][c];
                alien_pixel[1] |= green_pixels[r][c];
                alien_pixel[2] |= red_pixels[r][c];
            end
        end
        pixel[0] = alien_pixel[0] | alien_bullet_pixel[0];
        pixel[1] = alien_pixel[1] | alien_bullet_pixel[1];
        pixel[2] = alien_pixel[2] | alien_bullet_pixel[2];
    end

    always_comb begin
        aliens_remaining = 0;
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                if (alien_alive[r][c])
                    aliens_remaining++;
            end
        end
    end

//
    logic [$clog2(NUM_COLS)-1:0] leftmost_col [NUM_ROWS-1:0];
    logic [$clog2(NUM_COLS)-1:0] rightmost_col [NUM_ROWS-1:0];

    always_comb begin
        for (int r = 0; r < NUM_ROWS; r++) begin
            leftmost_col[r] = 0;
            rightmost_col[r] = NUM_COLS - 1;

            // Find leftmost alive
            for (int c = 0; c < NUM_COLS; c++) begin
                if (alien_alive[r][c]) begin
                    leftmost_col[r] = c;
                    break;
                end
            end

            // Find rightmost alive
            for (int c = NUM_COLS - 1; c >= 0; c--) begin
                if (alien_alive[r][c]) begin
                    rightmost_col[r] = c;
                    break;
                end
            end
        end
    end
//

    assign alien_hit_out = |alien_hit_array;

    always_comb begin
        alien_reached_paddle = 0;
        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                if (alien_alive[r][c]) begin
                    if (
                        rhpos[r][c] >= paddle_left &&
                        lhpos[r][c] <= paddle_right &&
                        bvpos[r][c] >= paddle_top &&
                        tvpos[r][c] <= paddle_bottom
                    ) begin
                        alien_reached_paddle = 1;
                    end
                end
            end
        end
    end

    generate
        genvar r, c;
        for (r = 0; r < NUM_ROWS; r++) begin : row_loop
            for (c = 0; c < NUM_COLS; c++) begin : col_loop
                alien_single alien_inst (
                    .pixel_clk(pixel_clk),
                    .rst(rst),
                    .fsync(fsync),
                    .hpos(hpos),
                    .vpos(vpos),
                    .group_lhpos(row_lhpos[r]),
                    .group_tvpos(group_tvpos),
                    .row(r),
                    .col(c),
                    .speed((r % 2) ? speed : speed * -1), // Alternate speed for odd/even rows
                    .alien_hit(alien_hit_array[r][c]),
                    .pixel({red_pixels[r][c], green_pixels[r][c], blue_pixels[r][c]}),
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

    alien_bullet ab (
        .pixel_clk(pixel_clk),
        .rst(rst),
        .fsync(fsync),
        .fire(fire_alien_bullet),
        .alien_x(fire_x),
        .alien_y(fire_y),
        .hpos(hpos),
        .vpos(vpos),
        .pixel(alien_bullet_pixel),
        .bullet_active(alien_bullet_active)
    );

endmodule
