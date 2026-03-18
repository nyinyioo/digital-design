// synthesis verilog_input_version verilog_2001
module top_module(
    input a, 
    input b,
    output wire out_assign,
    output reg out_alwaysblock
); 

    //continuous assignment
    assign out_assign = a & b;

    //procedural assignment
    //verilog        always@(*)
    //systemVerilog  always_comb
    always@(*) begin
        out_alwaysblock = a & b;
    end

endmodule