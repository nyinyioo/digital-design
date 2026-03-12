module top_module(
    input clk,
    input areset,   
    input bump_left,
    input bump_right,
    output walk_left,
    output walk_right); 

   	parameter LEFT=0, RIGHT=1;
    reg state, next_state;
   
    always_comb begin
        case(state)
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
        case(state)
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