module top_module (
    input clk,
    input reset,
    input [31:0] in,
    output [31:0] out
);

    reg [31:0] d;
    reg [31:0] q;

    always @(posedge clk) begin
        d <= in;
    end

    assign q = (d & ~in);

    always @(posedge clk) begin
        if (reset) begin
            out <= 32'b0;
        end else begin
            out <=  out | q;
        end
    end
    

endmodule