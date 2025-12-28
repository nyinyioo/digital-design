module top_module (
	input clk,
	input L,
	input r_in,
	input q_in,
	output reg Q);


    reg d,qff;

    //CL input block
    always@(*) begin 
        case(L) 
            0: d = q_in;
            1: d = r_in;
        endcase
    end

    //state transition logic
    always@(posedge clk) begin
        qff<=d;
    end 

    //CL output block
    assign Q = qff;
endmodule