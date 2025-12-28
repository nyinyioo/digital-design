module top_module (
    input [3:0] SW,
    input [3:0] KEY,
    output [3:0] LEDR
); //

    wire w, L, E, clk;
    wire r3, r2, r1, r0;
    wire Q3, Q2, Q1, Q0;

    assign w = KEY[3];
    assign L = KEY[2];
    assign E = KEY[1];

    assign clk = KEY[0];

    assign r3 = SW[3];
    assign r2 = SW[2];
    assign r1 = SW[1];
    assign r0 = SW[0];

    MUXDFF m3 (clk, w, r3, E, L, Q3);
    MUXDFF m2 (clk, Q3, r2, E, L, Q2);
    MUXDFF m1 (clk, Q2, r1, E, L, Q1);
    MUXDFF m0 (clk, Q1, r0, E, L, Q0);

    assign LEDR[3] = Q3;
    assign LEDR[2] = Q2;
    assign LEDR[1] = Q1;
    assign LEDR[0] = Q0;


endmodule



module MUXDFF (
    input clk,
    input w, R, E, L,
    output Q
);
    
    reg d,q_in;
    wire out1;

     //CL input block
    always@(*) begin 
        case(E) 
            0: out1 = q_in;
            1: out1 = w;
        endcase
    end

    always@(*) begin 
        case(L) 
            0: d = out1;
            1: d = R;
        endcase
    end

    //state transition logic
    always@(posedge clk) begin
        q_in<=d;
    end 

    //CL output block
    assign Q = q_in;

endmodule
