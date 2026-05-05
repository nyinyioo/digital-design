module datapath(input logic slow_clock, input logic fast_clock, input logic resetb,
                input logic load_pcard1, input logic load_pcard2, input logic load_pcard3,
                input logic load_dcard1, input logic load_dcard2, input logic load_dcard3,
                output logic [3:0] pcard3_out,
                output logic [3:0] pscore_out, output logic [3:0] dscore_out,
                output logic [6:0] HEX5, output logic [6:0] HEX4, output logic [6:0] HEX3,
                output logic [6:0] HEX2, output logic [6:0] HEX1, output logic [6:0] HEX0);


//intermediate wires
logic [3:0] pcard1, pcard2, pcard3, dcard1, dcard2, dcard3;
logic [3:0] new_card;

//dealcard block
dealcard U0 (.clock(fast_clock), .resetb(resetb), .new_card(new_card));

// 6 reg4 blocks
reg4 U1 (.clk(slow_clock), .rst_n(resetb), .load(load_pcard1), .card_in(new_card), .card_out(pcard1));
reg4 U2 (.clk(slow_clock), .rst_n(resetb), .load(load_pcard2), .card_in(new_card), .card_out(pcard2));
reg4 U3 (.clk(slow_clock), .rst_n(resetb), .load(load_pcard3), .card_in(new_card), .card_out(pcard3));
reg4 U4 (.clk(slow_clock), .rst_n(resetb), .load(load_dcard1), .card_in(new_card), .card_out(dcard1));
reg4 U5 (.clk(slow_clock), .rst_n(resetb), .load(load_dcard2), .card_in(new_card), .card_out(dcard2));
reg4 U6 (.clk(slow_clock), .rst_n(resetb), .load(load_dcard3), .card_in(new_card), .card_out(dcard3));

//two scorehand blocks
scorehand U7 (.card1(pcard1), .card2(pcard2), .card3(pcard3), .total(pscore_out));
scorehand U8 (.card1(dcard1), .card2(dcard2), .card3(dcard3), .total(dscore_out));

// six card7segs
card7seg U9  (.SW (pcard1), .HEX0(HEX0));
card7seg U10 (.SW (pcard2), .HEX0(HEX1));
card7seg U11 (.SW (pcard3), .HEX0(HEX2));
card7seg U12 (.SW (dcard1), .HEX0(HEX3));
card7seg U13 (.SW (dcard2), .HEX0(HEX4));
card7seg U14 (.SW (dcard3), .HEX0(HEX5));

// assign outputs: pcards and dcards
assign pcard3_out = pcard3;

endmodule