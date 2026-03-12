module top_module (
    input clk,
    input enable,
    input S,
    input A, B, C,
    output Z ); 


/*
    SHIFT RIGHT
    ------------------
    q[7] ... q[1] q[0]
    q[6] ... q[0]   S
*/

reg[7:0] q;
wire[2:0] sel;
assign sel = {A,B,C};

//shift register
always@(posedge clk) begin
    if(enable) begin
        q[7] <= q[6];
        q[6] <= q[5];
        q[5] <= q[4];
        q[4] <= q[3];
        q[3] <= q[2];
        q[2] <= q[1];
        q[1] <= q[0];
        q[0] <= S;
    end

end

//mux
assign z = q[sel];
/*
always @(*) begin
    case (sel)
        3'b000: Z = q[0];
        3'b001: Z = q[1];
        3'b010: Z = q[2];
        3'b011: Z = q[3];
        3'b100: Z = q[4];
        3'b101: Z = q[5];
        3'b110: Z = q[6];
        3'b111: Z = q[7];
        default: Z = 1'b0;
    endcase
end
*/
endmodule