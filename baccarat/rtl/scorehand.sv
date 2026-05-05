module scorehand(
    input logic [3:0] card1, 
    input logic [3:0] card2, 
    input logic [3:0] card3, 
    output logic [3:0] total);

// The code describing scorehand will go here.  Remember this is a combinational
// block. The function is described in the handout. Be sure to review Verilog
// notes on bitwidth mismatches and signed/unsigned numbers.

    logic [5:0] intermediate;
    logic [3:0] c1, c2, c3;

    always_comb begin 
        // convert 10, J, Q, K to 0
        c1 = (card1 >= 4'd10) ? 4'd0 : card1;
        c2 = (card2 >= 4'd10) ? 4'd0 : card2;
        c3 = (card3 >= 4'd10) ? 4'd0 : card3;

        // Max Bits: 5 bits 
        // Zero-extend inputs to 6 bits for addition 
        // (this is more than enough since the max value is 27)
        intermediate = {2'b0, c1} + {2'b0, c2} + {2'b0, c3};
        
        // Max value intermediate: 27  
        // floor(27/10) = 2
        if (intermediate >= 20)
            total = intermediate - 20;
        else if (intermediate >= 10)
            total = intermediate - 10;
        else
            total = intermediate[3:0];
    end

endmodule
