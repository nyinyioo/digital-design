module top_module( 
    input a, b, sel,
    output out ); 

    always_comb begin
        unique case(sel)
            0: out = a;
            1: out = b;
        endcase
    end 
    
endmodule