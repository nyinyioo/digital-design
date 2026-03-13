module top_module(
    input  logic        clk,
    input  logic        load,
    input  logic [511:0] data,
    output logic [511:0] q
);


integer  i;
reg [511:0] next_q;

//CL BLOCK
always @(*) begin
    next_q = 512'b0;
    for (i = 0; i < 512; i = i + 1) begin
        if (i == 0) begin
            // L = 0
            next_q[i] = (1'b0 & ~q[i]) |
                        (q[i] & ~(1'b0 & q[i+1]));
        end
        else if (i == 511) begin
            // R = 0
            next_q[i] = (q[i-1] & ~q[i]) |
                        (q[i] & ~(q[i-1] & 1'b0));
        end
        else begin
            next_q[i] = (q[i-1] & ~q[i]) |
                        (q[i] & ~(q[i-1] & q[i+1]));
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


