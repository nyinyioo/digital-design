module top_module( 
    input [2:0] a, b,
    input cin,
    output [2:0] cout,
    output [2:0] sum );


    genvar i;
    generate
        for (i =0; i<3; i= i+1) begin: adders
            if (i== 0) begin
                assign sum[i] = a[0] ^ b[0] ^ cin;
                assign cout[i] =  (a[i] & b[i]) | (a[i] & cin) | (b[i] & cin);
            end else begin
                assign sum[i] = a[i] ^ b[i] ^ cout[i-1];
                assign cout[i] =  (a[i] & b[i]) | (a[i] & cout[i-1]) | (b[i] & cout[i-1]);
            end 
        end
    endgenerate
    
endmodule