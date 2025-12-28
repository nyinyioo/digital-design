module top_module (
    input clk,
    input w, R, E, L,
    output Q
);
    
    reg d,q_in;
    wire out1;

     //CL input block
    always@(*) begin 
        case(E) 
            0: out1 = q_in;
            1: out1 = w;
        endcase
    end

    always@(*) begin 
        case(L) 
            0: d = out1;
            1: d = R;
        endcase
    end

    //state transition logic
    always@(posedge clk) begin
        q_in<=d;
    end 

    //CL output block
    assign Q = q_in;


endmodule