//-----------------------------------------------------------------------------
// Module: hdmi_transmit
// Description: 
//   - Generates pixel clock and serial clock using MMCM.
//   - Handles reset synchronization based on MMCM locked signal.
//   - Generates horizontal and vertical positions (hpos, vpos) for video timing.
//   - Encodes pixel data into TMDS format and serializes it for HDMI transmission.
//-----------------------------------------------------------------------------

module hdmi_transmit(
    input                  clk125,             // Input 125 MHz clock
    input [7:0] pixel [0:2],                    // Input pixel data for RGB (0=Blue, 1=Green, 2=Red)

    // Video timing outputs
    output pixel_clk,                           // Generated pixel clock
    output rst,                                 // Reset signal (active high during MMCM lock delay)
    output active,                              // Active video region signal
    output fsync,                               // Frame synchronization pulse (start of frame)

    // Position outputs
    output reg signed [11:0] hpos,               // Horizontal pixel position (counts during active video)
    output reg signed [11:0] vpos,               // Vertical line position (counts per frame)

    // HDMI output signals
    output tmds_tx_clk_p,                        // TMDS clock differential positive
    output tmds_tx_clk_n,                        // TMDS clock differential negative
    output [2:0] tmds_tx_data_p,                  // TMDS data differential positive for RGB
    output [2:0] tmds_tx_data_n                   // TMDS data differential negative for RGB
);

    // Internal wires and registers
    wire serdes_clk;                             // 5x pixel clock used for serialization
    reg [7:0] rstcnt;                            // Reset counter after MMCM lock
    wire locked;                                 // MMCM lock indicator
    reg active_ff;                               // Delayed active signal for vpos counting
    wire hsync, hblank, vsync, vblank;            // Timing control signals
    wire [1:0] ctl [0:2];                        // Control signals for TMDS encoders
    wire [9:0] tmds_data [0:2];                  // 10-bit TMDS-encoded data for each color channel

    //-----------------------------------------------------------------------------
    // MMCM Instantiation: Generate pixel clock and serial clock from clk125 input
    //-----------------------------------------------------------------------------
    mmcm_0 mmcm_0_inst(
        .clk_in1(clk125),
        .clk_out1(pixel_clk),     // Pixel clock output
        .clk_out2(serdes_clk),    // 5x Pixel clock for serialization
        .locked(locked)           // MMCM lock signal
    );

    //-----------------------------------------------------------------------------
    // Reset Generation: Hold reset high until MMCM is locked and counter expires
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk or negedge locked) begin
        if (~locked) begin
            rstcnt <= 0;
        end else begin
            if (rstcnt != 8'hff) begin
                rstcnt <= rstcnt + 1;
            end
        end
    end

    assign rst = (rstcnt == 8'hff) ? 1'b0 : 1'b1; // Reset deasserts when rstcnt maxes out

    //-----------------------------------------------------------------------------
    // Video Timing Generator: Generates hsync, vsync, active_video, etc.
    //-----------------------------------------------------------------------------
    video_timing video_timing_inst(
        .clk(pixel_clk),
        .clken(1'b1),
        .gen_clken(1'b1),
        .sof_state(1'b0),
        .hsync_out(hsync),
        .hblank_out(hblank),
        .vsync_out(vsync),
        .vblank_out(vblank),
        .active_video_out(active),
        .resetn(~rst),
        .fsync_out(fsync)
    );

    //-----------------------------------------------------------------------------
    // Horizontal and Vertical Position Counters
    //-----------------------------------------------------------------------------
    always @(posedge pixel_clk) begin
        active_ff <= active; // Capture previous active signal

        // Horizontal position counter
        if (rst || ~active) begin
            hpos <= 0;
        end else begin
            hpos <= hpos + 1;
        end

        // Vertical position counter
        if (rst || fsync) begin
            vpos <= 0;
        end else if (~active && active_ff) begin
            vpos <= vpos + 1;
        end
    end

    //-----------------------------------------------------------------------------
    // TMDS Encoding: Pack control signals and pixel data for each color channel
    //-----------------------------------------------------------------------------
    assign ctl[0] = {vsync, hsync}; // Blue channel carries sync signals during blanking
    assign ctl[1] = 2'b00;           // Red and Green channels have no control signals
    assign ctl[2] = 2'b00;

    //-----------------------------------------------------------------------------
    // TMDS Encode + Serialize: Generate differential outputs for HDMI
    //-----------------------------------------------------------------------------
    generate
        genvar i;
        for (i = 0; i < 3; i = i + 1) begin : TMDS_CHANNELS
            // TMDS Encoder
            tmds_encode tmds_encode_inst(
                .pixel_clk(pixel_clk),
                .rst(rst),
                .ctl(ctl[i]),
                .active(active),
                .pdata(pixel[i]),
                .tmds_data(tmds_data[i])
            );

            // TMDS Serializer
            tmds_oserdes tmds_oserdes_inst(
                .pixel_clk(pixel_clk),
                .serdes_clk(serdes_clk),
                .rst(rst),
                .tmds_data(tmds_data[i]),
                .tmds_serdes_p(tmds_tx_data_p[i]),
                .tmds_serdes_n(tmds_tx_data_n[i])
            );
        end
    endgenerate

    //-----------------------------------------------------------------------------
    // TMDS Clock Channel: Constant pattern 1111100000 (50% duty cycle square wave)
    //-----------------------------------------------------------------------------
    tmds_oserdes tmds_oserdes_clock(
        .pixel_clk(pixel_clk),
        .serdes_clk(serdes_clk),
        .rst(rst),
        .tmds_data(10'b1111100000),
        .tmds_serdes_p(tmds_tx_clk_p),
        .tmds_serdes_n(tmds_tx_clk_n)
    );

endmodule
