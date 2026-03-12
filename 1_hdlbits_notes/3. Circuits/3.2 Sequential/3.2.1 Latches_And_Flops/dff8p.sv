module top_module (
    input clk,
    input reset,
    input [7:0] d,
    output [7:0] q
);

/*
0x34 ->     00110100
8'h34 -> 8'b00110100
*/

    always@(negedge clk) begin
        if (reset) begin
            q<= 8h'34;
        end else begin
            q<=d;
        end
    end

endmodule