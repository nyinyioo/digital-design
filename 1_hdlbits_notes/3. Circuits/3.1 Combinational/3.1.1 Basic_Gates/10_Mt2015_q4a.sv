module top_module (input x, input y, output z);

    //assign internal wires
    wire z1;

    //assign outputs
    assign z1 = (x^y);
    assign z = z1 & x;

endmodule
