module top_module( 
    input [254:0] in,
    output [7:0] out );

/*
count the number of 1's in the input vector
out = in[0] + in[1] + ... + in[254]
out = 0 + 1 + 0 + 1 = 2 
*/
    integer i;
    always@(*) begin
        out = 8'b0;
        for (i=0; i<255; i=i+1) begin
            out = out + in[i];
        end
    end
endmodule