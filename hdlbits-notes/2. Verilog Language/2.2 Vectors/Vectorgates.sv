module top_module( 
    input [2:0] a,
    input [2:0] b,
    output [2:0] out_or_bitwise,
    output out_or_logical,
    output [5:0] out_not
);
    always @(*) begin
        //out_or_bitwise
        out_or_bitwise[2] = (a[2] | b[2]);
        out_or_bitwise[1] = (a[1] | b[1]);
        out_or_bitwise[0] = (a[0] | b[0]);
        //out_or_logical
        out_or_logical = (a || b); //thats the bitwise or operator
        //out_not
        out_not[5:0] = {~b[2],~b[1],~b[0],~a[2],~a[1],~a[0]};
    end 
    

endmodule