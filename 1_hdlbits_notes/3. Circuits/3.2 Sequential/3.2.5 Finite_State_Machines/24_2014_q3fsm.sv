module top_module (
    input clk,
    input reset,
    input s,
    input w,
    output z
);
    //declare signals
    logic state, next_state;
    parameter A = 1'b0, B = 1'b1;

    //internal signals
    logic [1:0] count;
    logic [1:0] ones;

    // next state
    always_comb begin
        case(state)
            A: next_state = s ? B : A;
            B: next_state = B;
            default: next_state = A;
        endcase
    end

    // sequential block
    always_ff @(posedge clk) begin
        if (reset) begin 
            state <= A;
        end else begin 
            state <= next_state;
        end 
    end

    // cycle counter — counts 0,1,2 then resets
    always_ff @(posedge clk) begin
        if(reset) begin 
            count <= 0;
        end else begin
            case(state)
                A: count <= 0;
                B: count <= (count == 2) ? 0 : count + 1;
                default: count <= 0;
            endcase
        end
    end

    // ones counter — tracks w=1s per window
    always_ff @(posedge clk) begin
        if(reset) begin 
            ones <= 0;
        end else begin
            case(count)
                0: ones <= w ? 1 : 0;  
                1: ones <= ones + w;     
                2: ones <= ones + w;     
                default: ones <= 0;
            endcase
        end
    end

    // CL output block
    assign z = (state == B && count == 0 && ones == 2) ? 1 : 0;

endmodule
