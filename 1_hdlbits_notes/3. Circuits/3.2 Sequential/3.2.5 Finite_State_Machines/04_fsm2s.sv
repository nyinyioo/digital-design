module top_module(
    input clk,
    input areset,    // Asynchronous reset to OFF
    input j,
    input k,
    output out); //  

    parameter OFF=0, ON=1; 
    reg state, next_state;

    always @(*) begin
        case (state)
            ON  :  next_state = k ? OFF : ON;
            OFF :  next_state = j ? ON : OFF;
        endcase
    end

    always @(posedge clk, posedge areset) begin
        if (areset) begin  
            state <= OFF;
        end else  begin
            state <= next_state;
        end 
    end

    always@(*) begin
            case (state)
                ON:  out = 1;
                OFF: out = 0;
        
            endcase
        end

endmodule