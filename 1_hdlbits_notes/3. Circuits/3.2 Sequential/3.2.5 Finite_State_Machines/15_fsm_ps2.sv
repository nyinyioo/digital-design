
module top_module(
    input  clk,
    input [7:0] in,
    input reset,    // Synchronous reset
    output logic done); 

    //state assignments
    typedef enum logic[1:0] {
        s0 = 2'd0,
        s1 = 2'd1,
        s2 = 2'd2,
        s3 = 2'd3
    } state_t;

    state_t state, next_state;

    //internal wires
    logic [23:0] message = 24'b0;

    // State transition logic (combinational)
    always_comb begin
        unique case(state)
            s0: begin next_state = (in[3] == 1) ? s1 : s0; end
            s1: begin next_state = s2; end
            s2: begin next_state = s3; end
            s3: begin next_state = (in[3] == 1) ? s1 : s0; end
            default: next_state = s0;
        endcase
    end

    // State flip-flops (sequential)
    always@(posedge clk) begin
        if (reset) begin
            state <= s0;
        end else begin 
            state <= next_state;
        end 
    end

    always@(posedge clk) begin
        if (state == s0 && in[3] == 1) begin
            message[7:0] <= in;
        end else if (state == s1) begin
            message[15:8] <= in;
        end else if (state == s2) begin
            message[23:16] <= in;
        end else if (state == s3) begin
            message <= 24'b0;
        end 
    end 

    // Output logic 
    always_comb begin
        unique case(state)
            s0: done = 0;
            s1: done = 0;
            s2: done = 0;
            s3: done = 1;
            default: done = 0;
        endcase
    end 

endmodule