module top_module (
    input clk,
    input reset,
    input [3:1] s,
    output reg fr3,
    output reg fr2,
    output reg fr1,
    output reg dfr
);

parameter A=0, B1=1, B2=2, C1=3, C2=4, D=5;
reg [2:0] state, next_state;

// Next-state logic
always @(*) begin
    case(state)
        A:  next_state <= s[1] ? B1 : A;

        B1: next_state <= s[2] ? C1 :
                          s[1] ? B1 : A;

        B2: next_state <= s[2] ? C1 :
                          s[1] ? B2 : A;

        C1: next_state <= s[3] ? D  :
                          s[2] ? C1 :
                          s[1] ? B2 : A;

        C2: next_state <= s[3] ? D :
                          s[2] ? C2 :
                          s[1] ? B2 : A;

        D:  next_state <= s[3] ? D :
                          s[2] ? C2 :
                          s[1] ? B2 : A;
    endcase
end

always @(posedge clk) begin
    if (reset)
        state <= A;     
    else
        state <= next_state;
end


always @(*) begin
    case(state)
        A:{fr3,fr2,fr1,dfr} = 4'b1111;
        B1:{fr3,fr2,fr1,dfr} = 4'b0110;
        B2:{fr3,fr2,fr1,dfr} = 4'b0111;
        C1:{fr3,fr2,fr1,dfr} = 4'b0010;
        C2:{fr3,fr2,fr1,dfr} = 4'b0011;
        D:{fr3,fr2,fr1,dfr} = 4'b0000;
    endcase
end

endmodule