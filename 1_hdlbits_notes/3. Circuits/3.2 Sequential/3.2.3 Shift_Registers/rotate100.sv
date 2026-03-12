

module top_module(
    input clk,
    input load,
    input [1:0] ena,
    input [99:0] data,
    output reg [99:0] q); 

/*

Rotate Right  
---------------------
[q3] [q2] [q1] [q0]
[q0 ] [q3] [q2] [q1]

Rotate Left
[q3] [q2] [q1] [q0]
[q2 ] [q1] [q0] [q3]

*/

    parameter N =  99;

    always @(posedge clk ) begin
     if (load) begin
            q <= data;
        end else begin

            q <= (ena == 2'b01) ? {q[0], q[N:1]}  :   // rotate right
                 (ena == 2'b10) ? {q[N-1:0], q[N]} :   // rotate left
                                   q;                  // hold
                                   
        end
    end
endmodule