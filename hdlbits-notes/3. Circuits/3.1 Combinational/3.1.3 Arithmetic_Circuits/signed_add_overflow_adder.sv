module top_module (
    input [7:0] a,
    input [7:0] b,
    output [7:0] s,
    output overflow
); 

/*
    Note: 
    --------------------------------------------
    Two's Complement: 2^8 = 256 values: -128 to +127

    2's complement: 
        0101: +5
        a. invert: 1010
        b. add 1: 1011: -5

    Overflow happens: carry into sign bit = 1, and carry out = 1.
      01000011  (+67)
    + 01000011  (+67)
      -----------
      10000110  (-122)  ← overflow
*/

    wire carry[7:0];
    genvar i;
    generate
        for (i =0; i<8; i= i+1) begin: adders
            if (i== 0) begin
                assign s[i] = a[0] ^ b[0];
                assign carry[i] =  (a[i] & b[i]);
            end else begin
                assign s[i] = a[i] ^ b[i] ^ carry[i-1];
                assign carry[i] =  (a[i] & b[i]) | (a[i] & carry[i-1]) | (b[i] & carry[i-1]);
            end 
        end
    endgenerate

    assign overflow = carry[6] ^ carry[7];

endmodule