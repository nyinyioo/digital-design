module top_module (
    input        clk,
    input        reset,   // Synchronous active-high reset
    output [3:1]  ena,
    output [15:0] q
);


    reg [3:0] ones;
    reg [3:0] tens;
    reg [3:0] hundreds;
    reg [3:0] thousands;

    assign ena[1] = (ones == 4'd9);
    assign ena[2] = (ones == 4'd9) & (tens == 4'd9);
    assign ena[3] = (ones == 4'd9) & (tens == 4'd9) & (hundreds == 4'd9);

    always @(posedge clk) begin
        if (reset) begin
            ones      <= 4'd0;
            tens      <= 4'd0;
            hundreds  <= 4'd0;
            thousands <= 4'd0;
        end else begin
            // Ones digit (always enabled)
            if (ones == 4'd9)
                ones <= 4'd0;
            else
                ones <= ones + 4'd1;

            // Tens digit
            if (ena[1]) begin
                if (tens == 4'd9)
                    tens <= 4'd0;
                else
                    tens <= tens + 4'd1;
            end

            // Hundreds digit
            if (ena[2]) begin
                if (hundreds == 4'd9)
                    hundreds <= 4'd0;
                else
                    hundreds <= hundreds + 4'd1;
            end

            // Thousands digit
            if (ena[3]) begin
                if (thousands == 4'd9)
                    thousands <= 4'd0;
                else
                    thousands <= thousands + 4'd1;
            end
        end
    end

    // Pack outputs
    assign q[3:0]   = ones;
    assign q[7:4]   = tens;
    assign q[11:8]  = hundreds;
    assign q[15:12] = thousands;

endmodule