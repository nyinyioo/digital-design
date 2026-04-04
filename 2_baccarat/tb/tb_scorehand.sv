`timescale 1ns/1ps
module tb_scorehand();

    //declare intermediate signals
    logic [3:0] card1, card2, card3; 
    wire  [3:0] total;
    logic [3:0] c1, c2, c3;

    integer i, j, k;
    logic  [5:0] expected_intermediate;
    logic  [3:0] expected_total;

    // instantiate UUT
    scorehand UUT (
        .card1(card1),
        .card2(card2),
        .card3(card3),
        .total(total)
    );
    
    // start testbench
    initial begin
        for (i=0; i<14; i=i+1) begin
            for (j=0; j<14; j=j+1) begin
                for (k=0; k<14; k=k+1) begin
                    card1 = k; 
                    card2 = j; 
                    card3 = i;
                     
                    #1;

                    // convert 10, J, Q, K to 0
                    c1 = (card1 >= 4'd10) ? 4'd0 : card1;
                    c2 = (card2 >= 4'd10) ? 4'd0 : card2;
                    c3 = (card3 >= 4'd10) ? 4'd0 : card3;

                    expected_intermediate = (c1 + c2 + c3);
                    expected_total = expected_intermediate % 10;

                    assert(total == expected_total) else $fatal(1, "FAIL: card1=%0d, card2=%0d, card3=%0d, expected total=%0d, got total=%0d", card1, card2, card3, expected_total, total);
                end
            end
        end 

        $display("All tests passed!");
        $finish;
    end 
endmodule
