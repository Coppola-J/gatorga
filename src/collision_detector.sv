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

    output wire alien_hit
);



assign alien_hit = (!rst && fsync && bullet_active && alien_alive &&
                bullet_right >= alien_lhpos &&
                bullet_left  <= alien_rhpos &&
                bullet_bottom >= alien_tvpos &&
                bullet_top    <= alien_bvpos);

endmodule
