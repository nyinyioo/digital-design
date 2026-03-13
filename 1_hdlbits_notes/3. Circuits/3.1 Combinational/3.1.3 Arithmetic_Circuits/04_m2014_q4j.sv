module top_module (
    input [3:0] x,
    input [3:0] y, 
    output [4:0] sum);

    wire cout[3:0];
    genvar i;
    generate
        for (i =0; i<4; i= i+1) begin: adders
            if (i== 0) begin
                assign sum[i] = x[0] ^ y[0];
                assign cout[i] =  (x[i] & y[i]);
            end else begin
                assign sum[i] = x[i] ^ y[i] ^ cout[i-1];
                assign cout[i] =  (x[i] & y[i]) | (x[i] & cout[i-1]) | (y[i] & cout[i-1]);
            end 
        end
    endgenerate
    
    assign sum[4] = cout[3];
    
endmodule