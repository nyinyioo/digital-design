module top_module ( 
    input a, 
    input b, 
    input c,
    input d,
    output out1,
    output out2
);
    //by instance ~ we use the outside connections
    mod_a instance1(out1, out2, a, b, c, d);
    

endmodule