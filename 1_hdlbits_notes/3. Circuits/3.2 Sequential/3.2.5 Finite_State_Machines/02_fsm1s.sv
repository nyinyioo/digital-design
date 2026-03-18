// Note the Verilog-1995 module declaration syntax here:
module top_module(clk, reset, in, out);
    input clk;
    input reset;    // Synchronous reset to state B
    input in;
    output out;//  
    reg out;

    //state assignment
    typedef enum logic {
        A = 1'b0,
        B = 1'b1
    } state_t;
    state_t state, next_state;


    always @(posedge clk) begin
        if (reset) begin  
            state <= B;
        end else  begin
            state <= next_state;
        end 
    end 
    
    always_comb begin
        unique case (state)
            A :  next_state = in ? A : B;
            B :  next_state = in ? B : A;
        
        endcase
    end 
    
    always_comb begin
        unique case (state)
            A: out = 0;
            B: out = 1;
    
        endcase
        end
 

endmodule
