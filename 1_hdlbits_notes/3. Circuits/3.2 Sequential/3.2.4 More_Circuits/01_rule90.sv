module top_module(
    input clk,
    input load,
    input [511:0] data,
    output [511:0] q ); 


integer  i;
reg [511:0] next_q;

/*
    next_q[i] <= q[i-1] ^ q[i+1];
    0 | q[0] q[1] q[2] ... q[510] q[511] | 0

    next_q[0] =   q[1]
    next_q[1] =   q[0] ^ q[2]
    next_q[510] = q[509] ^ q[511]
    next_q[511] = q[510]  
*/

//CL BLOCK
always_comb begin
    next_q = 512'b0;
    for (i = 0; i < 512; i = i + 1) begin
        if (i==0) begin
            next_q[i] = 0 ^ q[i+1];
        end else if (i==511) begin
            next_q[i] = q[i-1] ^ 0;
        end else begin
            next_q[i] = q[i-1] ^ q[i+1];
        end
    end
end


always @(posedge clk) begin
    if (load)
        q <= data;
    else
        q <= next_q;
end

endmodule