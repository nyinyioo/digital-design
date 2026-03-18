module top_module (
    input clk,
    input areset,
    input x,
    output z
);  

    //assigning an integer directly to an enum variable is not allowed
    //in strict SystemVerilog

    // state assignment
    typedef enum logic[1:0] { 
        A = 2'd0, 
        B = 2'd1, 
        C = 2'd2 
    } state_t;

    state_t state, next_state;

    // Input CL Block
    always_comb begin 
        unique case(state)
            A: next_state = x ? B : A;
            B: next_state = x ? C : B;
            C: next_state = x ? C : B;
        endcase
    end
    
    // sequential block 
    
    always@(posedge clk or posedge areset) begin
        if( areset) begin
        	state <= state_t'(0); //explicit type 0
        end else begin
            state <= next_state;
        end 
    end
    
    //Output CL Block (mealy state + input)
    assign z = (state == B) ? 1 : 0;

endmodule