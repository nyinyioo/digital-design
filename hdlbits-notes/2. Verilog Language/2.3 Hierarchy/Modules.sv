module top_module ( input a, input b, output out );
    //by instance, use outside connections to the mod.
    //mod_a instance1(a,b,out);
    //by port, outside connection to the mod (). 
    mod_a instance2(.in1(a), .in2(b), .out(out));
    
endmodule