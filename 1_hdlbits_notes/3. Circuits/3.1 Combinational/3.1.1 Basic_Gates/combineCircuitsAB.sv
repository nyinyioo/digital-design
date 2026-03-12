module A (input x, input y, output z);
    wire z1;
    assign z1 = (x^y);
    assign z = z1 & x;
endmodule


module B( input x, input y, output z );
    assign z = (~x & ~y) | (x&y);
endmodule


module top_module (input x, input y, output z);
    wire z1,z2,z3,z4;
    A IA1(x,y,z1);
    A IA2(x,y,z3);
    B IB1(x,y,z2);
    B IB2(x,y,z4);
    assign z = (z1|z2) ^ (z3&z4);    
endmodule