module top_module (
    input clk,
    input resetn,
    input [3:1] r,
    output [3:1] g
); 

    //state assignment
    typedef enum logic [1:0] { 
        A  = 2'd0,
        G1 = 2'd1, 
        G2 = 2'd2,
        G3 = 2'd3
    } state_t;
    state_t state, next_state;

    //input CL block
    always_comb begin 
        unique case(state)
            A: begin
                if      (r[1])      next_state = G1; 
                else if (r[2])      next_state = G2;
                else if (r[3])      next_state = G3;
                else                next_state = A;
            end 
            G1: begin
                if      (r[1])      next_state = G1; 
                else                next_state = A;
            end 
            G2: begin
                if      (r[2])      next_state = G2;
                else                next_state = A;
            end 
            G3: begin
                if       (r[3])     next_state = G3; 
                else                next_state = A;
            end 
            default:                next_state = A;
        endcase
    end

    // sequential block
    always_ff @(posedge clk) begin
        if (!resetn) begin
            state <= A;
        end else begin
            state <= next_state;
        end
    end

    // Output logic
    assign g[1] = (state == G1);
    assign g[2] = (state == G2);
    assign g[3] = (state == G3);

endmodule