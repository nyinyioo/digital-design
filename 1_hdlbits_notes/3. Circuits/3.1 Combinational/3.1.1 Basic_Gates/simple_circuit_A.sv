module top_module (input x, input y, output z);

    wire z1;
    assign z1 = (x^y);
    assign z = z1 & x;

endmodule
