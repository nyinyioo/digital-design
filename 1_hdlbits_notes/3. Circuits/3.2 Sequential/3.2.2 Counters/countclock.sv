module top_module(
    input        clk,
    input        reset,
    input        ena,
    output reg   pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);

    //when we are at the last second of a minute/hour
    wire sec_roll = (ss == 8'h59);
    wire min_roll = (mm == 8'h59);

    always @(posedge clk) begin
        if (reset) begin
            ss <= 8'h00;
            mm <= 8'h00;
            hh <= 8'h12;
            pm <= 1'b0;
        end else if (ena) begin
            // --- seconds ---
            if (sec_roll) begin
                ss <= 8'h00;

                // --- minutes ---
                if (min_roll) begin
                    mm <= 8'h00;

                    // --- hours ---
                    if (hh == 8'h11) begin
                        // 11 -> 12 and toggle AM/PM
                        hh <= 8'h12;
                        pm <= ~pm;
                    end else if (hh == 8'h12) begin
                        // 12 -> 01, no toggle
                        hh <= 8'h01;
                    end else begin
                        // Normal BCD increment from 01..10
                        if (hh[3:0] == 4'd9) begin
                            hh[3:0] <= 4'd0;
                            hh[7:4] <= hh[7:4] + 4'd1; 
                        end else begin
                            hh[3:0] <= hh[3:0] + 4'd1;
                        end
                    end

                end else begin
                    // increment minutes BCD
                    if (mm[3:0] == 4'd9) begin
                        mm[3:0] <= 4'd0;
                        mm[7:4] <= mm[7:4] + 4'd1;
                    end else begin
                        mm[3:0] <= mm[3:0] + 4'd1;
                    end
                end

            end else begin
                // increment seconds BCD
                if (ss[3:0] == 4'd9) begin
                    ss[3:0] <= 4'd0;
                    ss[7:4] <= ss[7:4] + 4'd1;
                end else begin
                    ss[3:0] <= ss[3:0] + 4'd1;
                end
            end
        end
    end

endmodule
