module tb_card7seg();

    //declare intermediate signals
    logic [3:0] SW;
    wire  [6:0] HEX0;

    //instantiate UUT
    card7seg UUT(SW, HEX0);

    initial begin
        SW = 4'b0000; #1;
        assert (HEX0 == 7'b1111111) else $fatal(1, "HEX0 mismatch for input 0 (blank): Expected 7'b1111111, Got 7'b%07b", HEX0);

        SW = 4'b0001; #1;
        assert (HEX0 == 7'b0001000) else $fatal(1, "HEX0 mismatch for input 1 (Ace): Expected 7'b0001000, Got 7'b%07b", HEX0);

        SW = 4'b0010; #1;
        assert (HEX0 == 7'b0100100) else $fatal(1, "HEX0 mismatch for input 2: Expected 7'b0100100, Got 7'b%07b", HEX0);

        SW = 4'b0011; #1;
        assert (HEX0 == 7'b0110000) else $fatal(1, "HEX0 mismatch for input 3: Expected 7'b0110000, Got 7'b%07b", HEX0);

        SW = 4'b0100; #1;
        assert (HEX0 == 7'b0011001) else $fatal(1, "HEX0 mismatch for input 4: Expected 7'b0011001, Got 7'b%07b", HEX0);

        SW = 4'b0101; #1;
        assert (HEX0 == 7'b0010010) else $fatal(1, "HEX0 mismatch for input 5: Expected 7'b0010010, Got 7'b%07b", HEX0);

        SW = 4'b0110; #1;
        assert (HEX0 == 7'b0000010) else $fatal(1, "HEX0 mismatch for input 6: Expected 7'b0000010, Got 7'b%07b", HEX0);

        SW = 4'b0111; #1;
        assert (HEX0 == 7'b1111000) else $fatal(1, "HEX0 mismatch for input 7: Expected 7'b1111000, Got 7'b%07b", HEX0);

        SW = 4'b1000; #1;
        assert (HEX0 == 7'b0000000) else $fatal(1, "HEX0 mismatch for input 8: Expected 7'b0000000, Got 7'b%07b", HEX0);

        SW = 4'b1001; #1;
        assert (HEX0 == 7'b0010000) else $fatal(1, "HEX0 mismatch for input 9: Expected 7'b0010000, Got 7'b%07b", HEX0);

        SW = 4'b1010; #1;
        assert (HEX0 == 7'b1000000) else $fatal(1, "HEX0 mismatch for input 10 (displays 0): Expected 7'b1000000, Got 7'b%07b", HEX0);

        SW = 4'b1011; #1;
        assert (HEX0 == 7'b1100001) else $fatal(1, "HEX0 mismatch for input 11 (J): Expected 7'b1100001, Got 7'b%07b", HEX0);

        SW = 4'b1100; #1;
        assert (HEX0 == 7'b0011000) else $fatal(1, "HEX0 mismatch for input 12 (q): Expected 7'b0011000, Got 7'b%07b", HEX0);

        SW = 4'b1101; #1;
        assert (HEX0 == 7'b0001001) else $fatal(1, "HEX0 mismatch for input 13 (H): Expected 7'b0001001, Got 7'b%07b", HEX0);

        SW = 4'b1110; #1;
        assert (HEX0 == 7'b1111111) else $fatal(1, "HEX0 mismatch for input 14 (unused): Expected 7'b1111111, Got 7'b%07b", HEX0);

        SW = 4'b1111; #1;
        assert (HEX0 == 7'b1111111) else $fatal(1, "HEX0 mismatch for input 15 (unused): Expected 7'b1111111, Got 7'b%07b", HEX0);

        $display("All tests passed!");
        $finish;
    end
endmodule
