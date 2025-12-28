module top_module (
    input clk,
    input [7:0] in,
    output [7:0] pedge
);

/*
pedge = 1 if 

    in[i] was 0 last cycle
    in[i] is 1 this cycle

        _____
       |     |
   -ns-|D   Q|-s-
       |_____|


D  Q   pedge
-----------
0  0    0 
0  1    0
1  0    1
1  1    0

pedge = (~d & q);
*/

reg [7:0] d;
reg [7:0] q;

assign d = in;
always @(posedge clk) begin
    q <= d;
     //output bit should be set the cycle after
     // a 0 to 1 transition occurs.
    pedge = (d & ~q);
end


endmodule