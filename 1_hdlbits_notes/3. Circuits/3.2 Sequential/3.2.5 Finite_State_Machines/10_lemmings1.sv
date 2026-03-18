module top_module(
    input clk,
    input areset,   
    input bump_left,
    input bump_right,
    output walk_left,
    output walk_right); 

    
    typedef enum logic { 
        LEFT  = 1'b0, 
        RIGHT = 1'b1
    } state_t;

    state_t state, next_state;

    always_comb begin
        unique case(state)
            LEFT:  next_state = (bump_left) ? RIGHT : LEFT;
            RIGHT: next_state = (bump_right)? LEFT : RIGHT;
        endcase
    end

    always @(posedge clk, posedge areset) begin
        if (areset) begin
            state <= LEFT;
        end else begin
        	state <= next_state;
        end
    end
    
    always_comb begin
        unique case(state)
            LEFT: begin
                walk_right = 0;
                walk_left =1;
            end 
            RIGHT: begin
                walk_right = 1;
                walk_left =0;
            end
        endcase
    end

endmodule