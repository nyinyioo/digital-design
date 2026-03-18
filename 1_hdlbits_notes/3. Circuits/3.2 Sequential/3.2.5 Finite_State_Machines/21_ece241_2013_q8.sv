module top_module (
    input clk,
    input aresetn,    // Asynchronous active-low reset
    input x,
    output z
); 

    //state assignments
    typedef enum logic [1:0] { 
        A=2'd0, 
        B=2'd1, 
        C=2'd2
    } state_t;
    state_t state, next_state;

    // next state logic 
    always_comb begin
        case(state)
            A: next_state = x ? B : A;
            B: next_state = x ? B : C;
            C: next_state = x ? B : A;
            default: next_state = A;
        endcase
    end

    // sequential — async active-low reset
    always_ff @(posedge clk or negedge aresetn) begin
        if(!aresetn) begin
            state <= A;
        end else begin
            state <= next_state;
        end
    end

    // output logic (Mealy — output depends on state and input)
    always_comb begin
        case(state)
            A: z = 0;
            B: z = 0;
            C: z = x ? 1 : 0;  // z=1 in C and "101" 
            default: z = 0;
        endcase
    end

endmodule