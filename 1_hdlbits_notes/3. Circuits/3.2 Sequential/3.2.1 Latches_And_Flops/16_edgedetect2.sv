module top_module (
    input clk,
    input [7:0] in,
    output [7:0] anyedge
);

/*
    pedge = 1 if 

    in[i] was 0 last cycle
    in[i] is 1 this cycle

    in[i] was 1 last cycle
    in[i] is 0 this cycle


        _____
       |     |
   -ns-|D   Q|-s-
       |_____|


    D  Q   anyedge
    -----------
    0  0    0 
    0  1    1
    1  0    1
    1  1    0

    pedge = (~d & q);

    reminder: 
    -----------------------------
    | / & are bitwise operators
    || / && are logical operators

    bitwise: 

        a = 8'b10110010
        b = 8'b11001001
    -------------------
        y = 8'b10000000

    logical:  y = (a != 0) and (b != 0)

*/

reg [7:0] d;
reg [7:0] q;

assign d = in;
always @(posedge clk) begin
    q <= d;
    anyedge <= (d & ~q) | (~d & q);
end

endmodule