module top_module( 
    input [99:0] in,
    output [99:0] out
);


    /*
    Reverse the bits of the input vector
    out[0] should be in[99], out[1] should be in[98], ..., out[99] should be in[0]
    */

integer i;
always_comb begin
    for (int i =0; i<100 ; i = i +1)
        out[i] = in[99 - i];
end

endmodule