module top_module ( input x, input y, output z );
    
    /* 
    x y z
    0 0 1
    1 0 0
    0 1 0
    1 1 1 
    */
    
    assign z = (~x & ~y) | (x&y);

endmodule