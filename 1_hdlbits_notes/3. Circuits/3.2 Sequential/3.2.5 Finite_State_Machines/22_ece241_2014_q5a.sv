module top_module (
    input clk,
    input areset,
    input x,
    output z
);  

    // state assignment
    parameter A = 0, B = 1, C = 2;
    reg [1:0] state, next_state;

    // Input CL Block
    always@(*) begin 
        case(state)
            A: next_state = x ? B : A;
            B: next_state = x ? C : B;
            C: next_state = x ? C : B;
        endcase
    end
    
    // sequential block 
    always@(posedge clk or posedge areset) begin
        if( areset) begin
        	state <= 0;
        end else begin
            state <= next_state;
        end 
    end
    
    //Output CL Block (mealy state + input)
    assign z = (state == B) ? 1 : 0;

endmodule