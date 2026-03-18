module top_module (
    input clk,
    input in, 
    output out);


    reg q, d;

    //CL input block 
    always_comb begin
        d = (in ^ q);  
    end 
    
    //DFF state transition logic
    always@(posedge clk) begin
    	q<=d;
    end 

    //CL output block
    assign out = q;

endmodule





