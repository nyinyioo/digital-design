module top_module (
    input clk,
    input resetn,    // active-low synchronous reset
    input x,
    input y,
    output f,
    output g
); 


    //state assignments 
    reg [3:0] state, next_state;
    parameter A = 4'd0, B = 4'd1, C = 4'd2, D = 4'd3, E = 4'd4, F = 4'd5, G = 4'd6, H = 4'd7, I = 4'd8;


    //input CL Block
    always_comb begin 
        case(state)
            A: begin
                next_state = B;
            end
            B: begin    
                next_state = C;
            end
            C: begin
                next_state =  x ? D : C;
            end
            D: begin
                next_state =  x ? D : E;
            end
            E: begin
                next_state =  x ? F : C;
            end
            F: begin
                next_state =  y ? H : G;
            end
            G: begin
                next_state =  y ? H : I;
            end
            H: begin
                next_state = H; 
            end
            I: begin
                next_state = I;
            end
             default: next_state = A;
        endcase
    end



    //sequential block
    always @(posedge clk) begin
        if (!resetn) begin
            state <= A;
        end else begin
            state <= next_state;
        end
    end

    //output logic
    assign f = (state == B);
    assign g = (state == F) || (state == G) || (state == H);
    
endmodule
