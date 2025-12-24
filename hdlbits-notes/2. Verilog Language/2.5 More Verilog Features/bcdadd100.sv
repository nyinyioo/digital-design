module top_module( 
    input [399:0] a, b,
    input cin,
    output cout,
    output [399:0] sum );

/*
BCD digit	Bits
Digit 0	    [    3 :   0]
Digit 1   	[    7 :   4]
Digit i	    [4*i+3 : 4*i]
cin → FA0 → carry[0] → FA1 → carry[1] → ... → FA99 → cout

*/
genvar i;
wire [99:0] carry;
    generate
        for (i = 0; i < 100; i = i + 1) begin : bcd_adders
            if (i == 0) begin
                bcd_fadd fa (
                    .a   (a[3:0]),
                    .b   (b[3:0]),
                    .cin (cin),
                    .cout(carry[0]),
                    .sum (sum[3:0])
                );
            end else begin
                bcd_fadd fa (
                    .a   (a[4*i+3 : 4*i]),
                    .b   (b[4*i+3 : 4*i]),
                    .cin (carry[i-1]),
                    .cout(carry[i]),
                    .sum (sum[4*i+3 : 4*i])
                );
            end
        end
    endgenerate

    assign cout = carry[99];

endmodule  
