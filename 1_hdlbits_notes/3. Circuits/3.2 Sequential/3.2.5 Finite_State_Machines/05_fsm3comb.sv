module top_module(
    input in,
    input [1:0] state,
    output [1:0] next_state,
    output out); //
    
    //ports declared; use parameter
    parameter A=0, B=1, C=2, D=3;
    
    // State transition logic: next_state = f(state, in)
    // Output logic:  out = f(state) for a Moore state machine

    //CL LOGIC
    always_comb begin
        unique case (state)
            A  :  next_state = in ? B : A;
            B  :  next_state = in ? B : C;
            C  :  next_state = in ? D : A;
            D  :  next_state = in ? B : C;
        endcase
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