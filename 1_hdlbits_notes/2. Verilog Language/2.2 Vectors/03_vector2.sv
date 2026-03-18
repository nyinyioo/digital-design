module top_module( 
    input [31:0] in,
    output [31:0] out );//

    wire[7:0] a,b,c,d;

    always@(in) begin
        a = in[31:24];
        b = in[23:16];
        c = in[15:8];
        d = in[7:0];
        out = {d,c,b,a};
    end
    
endmodule