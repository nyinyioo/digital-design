module top_module (
    input clk,
    input [2:0] y,
    input x,
    output Y0,
    output z
);

    /* 
    y=000, x=0 → next=000 → Y0=0
    y=000, x=1 → next=001 → Y0=1
    y=001, x=0 → next=001 → Y0=1
    y=001, x=1 → next=100 → Y0=0
    y=010, x=0 → next=010 → Y0=0
    y=010, x=1 → next=001 → Y0=1
    y=011, x=0 → next=001 → Y0=1
    y=011, x=1 → next=010 → Y0=0
    y=100, x=0 → next=011 → Y0=1
    y=100, x=1 → next=100 → Y0=0
    */

    logic [2:0] next_state;
    // next state logic
    always_comb begin
        case(y)
            3'b000: next_state = x ? 3'b001 : 3'b000;
            3'b001: next_state = x ? 3'b100 : 3'b001;
            3'b010: next_state = x ? 3'b001 : 3'b010;
            3'b011: next_state = x ? 3'b010 : 3'b001;
            3'b100: next_state = x ? 3'b100 : 3'b011;
            default: next_state = 3'b000;
        endcase
    end


    // outputs
    assign Y0 = next_state[0];
    assign  z = (y == 3'b011) || (y == 3'b100);

endmodule
