module top_module(
    input clk,
    input areset,    // Asynchronous reset to state B
    input in,
    output out);//  

    //state assignment
    typedef enum logic {
        A = 1'b0,
        B = 1'b1
    } state_t;
    state_t state, next_state;

    //CL BLOCK: state diagram
    always_comb begin    
        unique case (state) 
            A: begin next_state = in ? A : B; end
            B: begin next_state = in ? B : A; end
        endcase
    end
	
    //Sequential Block: state transition
    always @(posedge clk, posedge areset) begin   
        if (areset) begin
            state <= B;
        end else begin
            state <= next_state;
    end
    end
	
    //comb block: assigning outputs
    always_comb begin
        unique case (state)
            A: out = 0;
            B: out = 1;
        endcase
    end 
        
endmodule