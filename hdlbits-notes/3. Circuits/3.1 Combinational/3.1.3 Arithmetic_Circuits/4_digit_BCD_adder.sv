module top_module ( 
    input [15:0] a, b,
    input cin,
    output cout,
    output [15:0] sum );
    
    genvar i;
    wire [15:0] carry;
        generate
           for (i = 0; i < 4; i = i + 1) begin : bcd_adders
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

endmodule