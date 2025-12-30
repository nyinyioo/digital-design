module top_module(
    input clk,
    input in,
    input reset,
    output out); //

    reg [1:0] state, next_state;
    parameter A=0, B=1, C=2, D=3;

    //CL LOGIC
    always @(*) begin
        case (state)
            A  :  next_state = in ? B : A;
            B  :  next_state = in ? B : C;
            C  :  next_state = in ? D : A;
            D  :  next_state = in ? B : C;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin  
            state <= A;
        end else  begin
            state <= next_state;
        end 
    end

    always@(*) begin
            case (state)
                A  :  out = 0;
                B  :  out = 0;
                C  :  out = 0;
                D  :  out = 1;
            endcase
        end

endmodule