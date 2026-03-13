module top_module(
    input clk,
    input reset,    // Active-high synchronous reset to 32'h1
    output reg [31:0] q
);

    /*
    q[31] q[30] q[29] ... q[1] q[0]
    ?   q[31] q[30] ... q[2] q[1]


    q[31] q[30] q[29] ... q[1] q[0]
    q[0]  q[31] q[30] ... q[2] q[1]

    */

    always @(posedge clk) begin
        if (reset) begin
            q <= 32'h1;   // non-zero seed
        end else begin

            // Shift Left
            q[30:0] <= q[31:1];

            // MSB (x^32 term) taps: x^22, x^2, x^1
            q[31] <= q[0];
            q[21] <= q[22] ^ q[0];
            q[1]  <= q[2]  ^ q[0];
            q[0]  <= q[1]  ^ q[0];
        end
    end
endmodule