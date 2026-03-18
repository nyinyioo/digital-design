module muxDFF (
    input clk,
    input L,
    input r_in,
    input q_in,
    output reg Q
);
    reg d;

    always_comb begin 
        unique case (L)
            0: d = q_in;
            1: d = r_in;
        endcase
    end

    always @(posedge clk) begin
        Q <= d;
    end
endmodule


module top_module (
	input [2:0] SW,      // R
	input [1:0] KEY,     // L and clk
	output [2:0] LEDR);  // Q

    wire L;
    wire clk;
    wire r0, r1, r2;
    wire Q2,Q1,Q0;

    assign L = KEY[1];
    assign clk = KEY[0];
    assign r2 = SW[2];
    assign r1 = SW[1];
    assign r0 = SW[0];


    muxDFF m2 (clk, L, r2, (Q1^Q2), Q2);
    muxDFF m1 (clk, L, r1, (Q0), Q1 );
    muxDFF m0 (clk, L, r0, (Q2), Q0 );


    assign LEDR[2] = Q2;
    assign LEDR[1] = Q1;
    assign LEDR[0] = Q0;
endmodule


