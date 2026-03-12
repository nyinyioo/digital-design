module top_module (
    input clk,
    input areset,
    input x,
    output z
); 
    parameter A=0,B=1;
    reg state, next_state;
    always_comb begin
        case(state)
            A: next_state = (x == 1) ? B: A;
            B: next_state = (x == 0) ? B: B;
        endcase
    end
    

    always_ff@(posedge clk or posedge areset) begin
        if(areset) begin
            state <= A;
        end else begin
            state <= next_state;
        end 
    end
    
    
    //assign z = (state == A && x == 1) ? 1: 0;                 
    always_comb begin
        case(state)
            A: z = (x == 1) ? 1: 0;
            B: z = (x == 0) ? 1: 0;
        endcase
    end
endmodule