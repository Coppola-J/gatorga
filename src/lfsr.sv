//-----------------------------------------------------------------------------
// Module: lfsr
// Description: 
//  Random number generator using a Linear Feedback Shift Register (LFSR).
//-----------------------------------------------------------------------------

module lfsr (
    input  logic clk,
    input  logic rst,
    output logic [15:0] rnd
);
    logic [15:0] state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= 16'hACE1;
        else
            state <= {state[14:0], state[15] ^ state[13] ^ state[12] ^ state[10]};
    end

    assign rnd = state;
endmodule
