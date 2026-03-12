module top_module( 
    input a, 
    input b, 
    output out );
    always@ (a or b) begin
        out = a & b;
    end
endmodule
