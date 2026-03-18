module top_module (
    input [5:0] y,
    input w,
    output Y1,
    output Y3
);

    /* 
        a. truth table
        ---------------
        state   y[5:0]
        A     000001
        B     000010
        C     000100
        D     001000
        E     010000
        F     100000

        b. boolean equation
        -------------------
        Y1 = y[0] & w;
        Y3 = (y[1] | y[2] | y[4] | y[5]) & ~w;
    */

    assign Y1 = y[0] & w;
    assign Y3 = (y[1] | y[2] | y[4] | y[5]) & ~w;

endmodule

