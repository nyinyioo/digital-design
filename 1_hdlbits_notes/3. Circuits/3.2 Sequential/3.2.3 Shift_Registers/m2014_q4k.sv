module dff_m (
    input clk,  
    input resetn,  
    input d,
    output q );

    always@ (posedge clk) begin
         if (~resetn) begin
            q<=1'b0;
         end else begin
            q <= d;
         end
    end

endmodule


module top_module (
    input clk,
    input resetn,   // synchronous reset
    input in,
    output out);

    logic q1,q2,q3,q4;

    dff_m m1 (clk, resetn, in, q1);
    dff_m m2 (clk, resetn, q1, q2);
    dff_m m3 (clk, resetn, q2, q3);
    dff_m m4 (clk, resetn, q3, q4);

    assign out = q4;

endmodule