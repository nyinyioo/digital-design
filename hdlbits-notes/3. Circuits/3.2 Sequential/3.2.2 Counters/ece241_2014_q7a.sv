module top_module (
    input clk,
    input reset,
    input enable,
    output [3:0] Q,
    output c_enable,
    output c_load,
    output [3:0] c_d
); 



    // Control logic
    assign c_load   = reset | (enable & (Q == 4'd12));
    assign c_d      = 4'd1;
    assign c_enable = enable & ~c_load;


    count4 the_counter (clk, c_enable, c_load, c_d, Q ); 



endmodule