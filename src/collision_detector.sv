module collision_controller (
    input pixel_clk,
    input rst,
    input fsync,

    input logic bullet_active,
    input logic alien_alive,

    input signed [11:0] bullet_left,
    input signed [11:0] bullet_right,
    input signed [11:0] bullet_top,
    input signed [11:0] bullet_bottom,

    input signed [11:0] alien_lhpos,
    input signed [11:0] alien_rhpos,
    input signed [11:0] alien_tvpos,
    input signed [11:0] alien_bvpos,

    output logic alien_hit
);

    always_ff @(posedge pixel_clk) begin
        if (rst) begin
            alien_hit <= 1'b0;
        end else if (fsync) begin
            if (bullet_active && alien_alive &&
                bullet_right >= alien_lhpos &&
                bullet_left  <= alien_rhpos &&
                bullet_bottom >= alien_tvpos &&
                bullet_top    <= alien_bvpos) begin
                alien_hit <= 1'b1;
            end else begin
                alien_hit <= 1'b0;
            end
        end
    end

endmodule
