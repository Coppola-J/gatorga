import params::*;

module ready_up_screen (
    input        pixel_clk,
    input        rst,
    input        fsync,
    input  logic [1:0]  game_state,
    input  logic signed [11:0] hpos,
    input  logic signed [11:0] vpos,

    output logic [7:0]  pixel [0:2],
    output logic        use_ready_up_pixels
);

// TODO: HAVE ALIENS GO ACROSS THE SCREEN AT RANDOM SPEEDS AND COLORS AND SHOOT AND DISSAPPEAR FOR IMMERSIVE READY UP SCREEN

    // Game state constants
    localparam logic [1:0] START_SCREEN = 2'd0;

    // Title positioning
    localparam TITLE_WIDTH  = 256;
    localparam TITLE_HEIGHT = 64;
    localparam TITLE_HSTART = (HRES - TITLE_WIDTH) >> 1;
    localparam TITLE_VSTART = 300;

    // READY UP positioning
    localparam READY_WIDTH  = 128;
    localparam READY_HEIGHT = 32;
    localparam READY_HSTART = (HRES - READY_WIDTH) >> 1;
    localparam READY_VSTART = 400;

    // Bitmap outputs
    wire [255:0] title_bits;
    wire [127:0] ready_bits;

    // Blinking logic
    reg [23:0] blink_counter;
    wire show_ready;

    always_ff @(posedge pixel_clk) begin
        if (rst)
            blink_counter <= 0;
        else
            blink_counter <= blink_counter + 1;
    end

    assign show_ready = blink_counter[23]; // Toggle every ~0.3 sec at 100MHz

    // ROM instances
    title_bitmap title_rom (
        .clka(pixel_clk),
        .ena(1'b1),
        .addra(vpos - TITLE_VSTART),
        .douta(title_bits)
    );

    ready_up_bitmap ready_rom (
        .clka(pixel_clk),
        .ena(1'b1),
        .addra(vpos - READY_VSTART),
        .douta(ready_bits)
    );


    wire title_active;
    wire ready_active;

    // Visibility checks
    assign title_active = (game_state == START_SCREEN) &&
                        (vpos >= TITLE_VSTART && vpos < TITLE_VSTART + TITLE_HEIGHT) &&
                        (hpos >= TITLE_HSTART && hpos < TITLE_HSTART + TITLE_WIDTH) &&
                        (title_bits[TITLE_WIDTH - 1 - (hpos - TITLE_HSTART)]);

    assign ready_active = (game_state == START_SCREEN) && show_ready &&
                        (vpos >= READY_VSTART && vpos < READY_VSTART + READY_HEIGHT) &&
                        (hpos >= READY_HSTART && hpos < READY_HSTART + READY_WIDTH) &&
                        (ready_bits[READY_WIDTH - 1 - (hpos - READY_HSTART)]);

    assign pixel[2] = title_active ? TITLE_COLOR[23:16] :
                      ready_active ? READY_COLOR[23:16] : 8'h00;

    assign pixel[1] = title_active ? TITLE_COLOR[15:8] :
                      ready_active ? READY_COLOR[15:8] : 8'h00;

    assign pixel[0] = title_active ? TITLE_COLOR[7:0] :
                      ready_active ? READY_COLOR[7:0] : 8'h00;

    assign use_ready_up_pixels = (game_state == START_SCREEN);

endmodule
