module top_module (
    input [7:0] a, b, c, d,
    output [7:0] min);

    //assign internal signals
    wire [7:0] intermediate_result1, intermediate_result2; 

    //assign outputs
    assign intermediate_result1 = ((c >= d) ? d:c); 
    assign intermediate_result2 = ((a >= b) ? b:a);
    assign min = ((intermediate_result1 >= intermediate_result2) ? intermediate_result2 : intermediate_result1);
    
endmodule