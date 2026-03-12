module top_module (
    input clk,
    input x,
    output z
); 

    wire n1,n2,n3;
    reg q1,q2,q3;

    always @(*) begin
        n1 = (x ^   q1);
        n2 = (x &  ~q2);
        n3 = (x || ~q3);
    end

    always@(posedge clk) begin
        q1<=n1;
        q2<=n2;
        q3<=n3;
    end

    assign z = ~(q1 || q2 || q3);
    
endmodule