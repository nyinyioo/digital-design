module top_module(
    input clk,
    input reset,    // Active-high synchronous reset to 5'h1
    output [4:0] q
); 

    /*
    Reminder: 
        Outputs driven by always, must be reg
        Module cannot be instantiated inside procedural blocks.

    Notes:
        Galois LFSR  linear feedback shift register 
        A maximum-length LFSR of n bits cycles through 2n-1 states before repeating 
        
        For an n-bit LFSR, a polynomial looks like: xⁿ + xᵏ + xᵐ + ... + 1
        Polynomial term x^k ⇒ XOR feedback into q[k-1]
        x³ + x + 1              -> n=3, q[2:0]  ~ x¹ → q[1-1] = q[0] <= q[1] ^ q[0]

        x⁵ + x³ + 1             -> n=5  q[4:0]  ~ x³ → q[3-1] = q[2] <= q[3] ^ q[0];

        x⁸ + x⁶ + x⁵ + x⁴ + 1   -> x⁶ → q[5] q[7:0] ~  q[5] <= q[6] ^ q[0];
                                   x⁵ → q[4]           q[4] <= q[5] ^ q[0];
                                   x⁴ → q[3]           q[3] <= q[4] ^ q[0];


        An LFSR is a tiny hardware circuit that generates a long sequence of bits
        that looks random, but is completely deterministic and repeatable.

    */

always @(posedge clk) begin
        if (reset) begin
            q <= 5'b00001;   
        end else begin
            q[0] <= q[1];
            q[1] <= q[2];
            q[2] <= q[3] ^ q[0];  
            q[3] <= q[4];
            q[4] <= q[0] ^ 0;        
        end
    end
endmodule