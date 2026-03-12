module top_module(
    input clk,
    input [7:0] in,
    input reset,  // Synchronous reset
    output [23:0] out_bytes,
    output done);

    parameter s0 = 0, s1 = 1, s2 = 2, s3 = 3;
    logic [1:0] state, next_state;
    logic [23:0] message;

    // State transition logic (combinational)
    always_comb begin
        case(state)
            s0: next_state = (in[3] == 1) ? s1 : s0;
            s1: next_state = s2;
            s2: next_state = s3;
            s3: next_state = (in[3] == 1) ? s1 : s0;
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

    // output based on next_state transiton
    always@(posedge clk) begin
        if (reset) begin
            message <= 24'b0;
        end else begin
            case(next_state)
                s1: message[23:16] <= in;      // Capture 1st byte when transitioning to s1
                s2: message[15:8]  <= in;      // Capture 2nd byte when transitioning to s2
                s3: message[7:0]   <= in;      // Capture 3rd byte when transitioning to s3
                default: message   <= message; // Hold value otherwise
            endcase
        end
    end

    // Output logic
    assign done = (state == s3);
    assign out_bytes = message;

endmodule