module top_module(
    input clk,
    input areset,    // Asynchronous reset to OFF
    input j,
    input k,
    output out); 

    //state assignment
    //port not given, use typedef enum
    typedef enum logic {
        OFF = 1'b0,
        ON = 1'b1
    } state_t;

    state_t state, next_state;

    //input CL Block
    always_comb begin
        unique case (state)
            ON  :  next_state = k ? OFF : ON;
            OFF :  next_state = j ? ON : OFF;
        endcase
    end

    //Sequential Block
    always @(posedge clk, posedge areset) begin
        if (areset) begin
            state <= OFF;
        end else  begin
            state <= next_state;
        end
    end

    //output CL Block
    always_comb begin
            unique case (state)
                ON:  out = 1;
                OFF: out = 0;
        
            endcase
        end

endmodule