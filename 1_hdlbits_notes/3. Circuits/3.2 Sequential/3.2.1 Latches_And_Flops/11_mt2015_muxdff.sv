module top_module (
    input clk,
    input L,
    input r_in,
    input q_in,
    output reg Q
);
    reg d;

    always_comb begin
        unique case (L)
            0: d = q_in;
            1: d = r_in;
        endcase
    end

    always @(posedge clk) begin
        Q <= d;
    end

endmodule