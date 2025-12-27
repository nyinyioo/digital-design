module top_module( 
    input [99:0] a, b,
    input cin,
    output cout,
    output [99:0] sum );
    
    wire cout_temp[99:0];
    genvar i;
    generate
        for (i =0; i<100; i= i+1) begin: adders
            if (i== 0) begin
                assign sum[i] = a[0] ^ b[0] ^ cin;
                assign cout_temp[i] =  (a[i] & b[i]) | (a[i] & cin) | (b[i] & cin);
            end else begin
                assign sum[i] = a[i] ^ b[i] ^ cout_temp[i-1];
                assign cout_temp[i] =  (a[i] & b[i]) | (a[i] & cout_temp[i-1]) | (b[i] & cout_temp[i-1]);
            end 
        end
    endgenerate
    assign cout = cout_temp[99];

endmodule
