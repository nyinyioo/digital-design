module top_module (
    input clk,
    input reset,     // synchronous reset
    input w,
    output z);

    //state assignment
    typedef enum logic[3:0] { 
        A = 4'd0,
        B = 4'd1, 
        C = 4'd2, 
        D = 4'd3, 
        E = 4'd4, 
        F = 4'd5
    } state_t;
    state_t state, next_state;

    //input CL Block
    always_comb begin 
        unique case(state)
            A: next_state = w ? A : B;
            B: next_state = w ? D : C;
            C: next_state = w ? D : E;
            D: next_state = w ? A : F;
            E: next_state = w ? D : E;
            F: next_state = w ? D : C;
        endcase
    end

    //sequential state assignment - synchronous reset
    always@(posedge clk ) begin 
        if (reset) begin
            state <= A; 
        end else begin 
            state <= next_state;
        end
    end

    //output CL logic block
    always_comb begin 
        unique case(state)
            A: z = 0;
            B: z = 0;
            C: z = 0;
            D: z = 0;
            E: z = 1;
            F: z = 1;
        endcase
    end

endmodule

