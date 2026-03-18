module top_module(
    input clk,
    input in,
    input areset,
    output out); //

    //state assignment
    typedef enum logic [1:0] {
        A = 2'd0,
        B = 2'd1,
        C = 2'd2,
        D = 2'd3
    } state_t;

    state_t state, next_state;

    //CL LOGIC
    always_comb begin
        unique case (state)
            A  :  next_state = in ? B : A;
            B  :  next_state = in ? B : C;
            C  :  next_state = in ? D : A;
            D  :  next_state = in ? B : C;
        endcase
    end

    always @(posedge clk, posedge areset) begin
        if (areset) begin  
            state <= A;
        end else  begin
            state <= next_state;
        end 
    end

    always_comb begin
            unique case (state)
                A  :  out = 0;
                B  :  out = 0;
                C  :  out = 0;
                D  :  out = 1;
            endcase
        end

endmodule