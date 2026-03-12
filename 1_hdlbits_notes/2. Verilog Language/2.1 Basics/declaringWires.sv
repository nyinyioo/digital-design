`default_nettype none
module top_module(
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n   ); 
    always@(*) begin
        out = ((a&b) | (c&d));
        out_n = ~((a&b) | (c&d));
        
    end

endmodule