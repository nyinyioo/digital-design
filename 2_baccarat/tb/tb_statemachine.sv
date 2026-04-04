`timescale 1ns/1ps

module tb_statemachine();

    // Test bench for state machine 

    // State sequence: We always start the game with four cards being dealt and then hcecking for a natural so:
    //                 START -> S0 -> S1 -> S2 -> CHECK_NAT -> ...
    // Then from CHECK_NAT there are 4 main paths to take 
    // 1) NATURAL (pscore or dscore is 8 or 9):
    //                 CHECK_NAT -> CHECK_SCORE -> (PLAYER_WINS or DEALER_WINS or TIE (lets call these the terminal states)) then spin at same state 
    // 2) Player draws 3rd card (pscore <= 5), Dealer does not draw:
    //                 CHECK_NAT -> DEAL_P3 -> DECIDE_D3 -> CHECK_SCORE -> terminal 
    // 3) Player draws 3rd card (pscore <= 5), Dealer draws based on dscore + pcard3_value:
    //                 CHECK_NAT -> DEAL_P3 -> DECIDE_D3 -> DEAL_D3 -> CHECK_SCORE -> terminal
    // 4) Player stands (pscore = 6 or 7), dealer may draw if dscore <= 5:
    //                 CHECK_NAT -> DEAL_D3 -> CHECK_SCORE -> terminal
    //                 OR (if dscore >= 6) CHECK_NAT -> CHECk_SCORE -> terminal

    // We need to test every state is outputing the right load signals, winner lights are asserted at right states, and that the transitions are correct

    // Testbench signals
    logic slow_clock;
    logic resetb;
    logic [3:0] dscore, pscore, pcard3;
    wire load_pcard1, load_pcard2, load_pcard3;
    wire load_dcard1, load_dcard2, load_dcard3;
    wire player_win_light, dealer_win_light;
    
    // Instantiate DUT
    statemachine dut (
        .slow_clock(slow_clock),
        .resetb(resetb),
        .dscore(dscore),
        .pscore(pscore),
        .pcard3(pcard3),
        .load_pcard1(load_pcard1),
        .load_pcard2(load_pcard2),
        .load_pcard3(load_pcard3),
        .load_dcard1(load_dcard1),
        .load_dcard2(load_dcard2),
        .load_dcard3(load_dcard3),
        .player_win_light(player_win_light),
        .dealer_win_light(dealer_win_light)
    );
    
    //clk generation
    initial begin
        slow_clock = 1'b0;
        forever #10 slow_clock = ~slow_clock;
    end

    //begin testbench
    initial begin

        // Default inputs 
        pscore = 4'd0;
        dscore = 4'd0;
        pcard3 = 4'd0;


        // reset (active low)
		resetb = 1'b0;
		@(posedge slow_clock);
		@(posedge slow_clock);
		resetb = 1'b1;  // Deassert reset


        // TEST 1: NATURAL -> PLAYER_WINS
        // Make natural true and ensure pscore > dscore at CHECK_SCORE.
        $display("\nTEST 1: NATURAL -> PLAYER_WINS -> HOLD");

        // Set the inputs accordingly
        pscore = 4'd8;
        dscore = 4'd7;
        pcard3 = 4'd0;

        // After reset release, FSM sits in START until the next posedge transition sequence begins.
        // Check START output (load_pcard1)
        #1;
        assert(load_pcard1 && !load_dcard1 && !load_pcard2 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "START outputs wrong (expected load_pcard1=1 only)");

        // Advance to S0
        @(posedge slow_clock); #1;
        assert(load_dcard1 && !load_pcard1 && !load_pcard2 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "S0 outputs wrong (expected load_dcard1=1 only)");

        // Advance to S1
        @(posedge slow_clock); #1;
        assert(load_pcard2 && !load_pcard1 && !load_dcard1 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "S1 outputs wrong (expected load_pcard2=1 only)");

        // Advance to S2
        @(posedge slow_clock); #1;
        assert(load_dcard2 && !load_pcard1 && !load_dcard1 && !load_pcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "S2 outputs wrong (expected load_dcard2=1 only)");

        // Advance to CHECK_NAT (no loads)
        @(posedge slow_clock); #1;
        assert(!load_pcard1 && !load_dcard1 && !load_pcard2 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "CHECK_NAT outputs wrong (expected all loads 0)");

        // Next: CHECK_SCORE (still no loads)
        @(posedge slow_clock); #1;
        assert(!load_pcard1 && !load_dcard1 && !load_pcard2 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "CHECK_SCORE outputs wrong (expected all loads 0)");

        // Next: PLAYER_WINS (player light on)
        @(posedge slow_clock); #1;
        assert(player_win_light && !dealer_win_light)
            else $fatal(1, "PLAYER_WINS outputs wrong (expected player_win_light=1 only)");

        // HOLD check: should remain in PLAYER_WINS with same light, no loads
        @(posedge slow_clock); #1;
        assert(player_win_light && !dealer_win_light)
            else $fatal(1, "PLAYER_WINS did not hold (light changed)");
        assert(!load_pcard1 && !load_dcard1 && !load_pcard2 && !load_dcard2 && !load_pcard3 && !load_dcard3)
            else $fatal(1, "PLAYER_WINS hold state should not assert any loads");

        // Reset between tests
        resetb = 1'b0;
        @(posedge slow_clock);
        @(posedge slow_clock);
        resetb = 1'b1;
        #1;

        // TEST 2: NATURAL -> DEALER_WINS
        // Example: dscore=9 (natural), pscore=7 => dealer wins.
        $display("\nTEST 2: NATURAL -> DEALER_WINS -> HOLD");

        pscore = 4'd7;
        dscore = 4'd9;
        pcard3 = 4'd0;

        // Walk to CHECK_NAT quickly (we already tested the load pulses above, so here we just step)
        // START
        #1;
        // S0
        @(posedge slow_clock);
        // S1
        @(posedge slow_clock);
        // S2
        @(posedge slow_clock);
        // CHECK_NAT
        @(posedge slow_clock);
        // CHECK_SCORE
        @(posedge slow_clock);
        // DEALER_WINS
        @(posedge slow_clock); #1;

        assert(!player_win_light && dealer_win_light)
            else $fatal(1, "DEALER_WINS outputs wrong (expected dealer_win_light=1 only)");

        // HOLD check
        @(posedge slow_clock); #1;
        assert(!player_win_light && dealer_win_light)
            else $fatal(1, "DEALER_WINS did not hold");

        // Reset between tests
        resetb = 1'b0;
        @(posedge slow_clock);
        @(posedge slow_clock);
        resetb = 1'b1;
        #1;

        // TEST 3: NATURAL -> TIE
        $display("\nTEST 3: NATURAL -> TIE -> HOLD");

        pscore = 4'd8;
        dscore = 4'd8;
        pcard3 = 4'd0;

        // Walk to TIE
        @(posedge slow_clock); // S0
        @(posedge slow_clock); // S1
        @(posedge slow_clock); // S2
        @(posedge slow_clock); // CHECK_NAT
        @(posedge slow_clock); // CHECK_SCORE
        @(posedge slow_clock); // TIE
        #1;

        assert(player_win_light && dealer_win_light)
            else $fatal(1, "TIE outputs wrong (expected both win lights = 1)");

        // HOLD check
        @(posedge slow_clock); #1;
        assert(player_win_light && dealer_win_light)
            else $fatal(1, "TIE did not hold");

        // Reset between tests
        resetb = 1'b0;
        @(posedge slow_clock);
        @(posedge slow_clock);
        resetb = 1'b1;
        #1;

        // TEST 4: Player draws P3, Dealer draws D3 (path uses DECIDE_D3 then DEAL_D3)
        // Expected:
        // START S0 S1 S2 CHECK_NAT -> DEAL_P3 -> DECIDE_D3 -> DEAL_D3 -> CHECK_SCORE -> terminal
        $display("\nTEST 4: DEAL_P3 -> DECIDE_D3 -> DEAL_D3 path");

        pscore = 4'd4;   // player draws
        dscore = 4'd3;   // dealer decision depends on pcard3_value != 8
        pcard3 = 4'd5;   // player's 3rd card value is 5 (not 8)

        // Walk to CHECK_NAT
        @(posedge slow_clock); // S0
        @(posedge slow_clock); // S1
        @(posedge slow_clock); // S2
        @(posedge slow_clock); // CHECK_NAT
        #1;

        // Next should be DEAL_P3 (load_pcard3 asserted)
        @(posedge slow_clock); #1;
        assert(load_pcard3 && !load_dcard3)
            else $fatal(1, "DEAL_P3 outputs wrong (expected load_pcard3=1)");

        // Next DECIDE_D3 (no loads)
        @(posedge slow_clock); #1;
        assert(!load_pcard3 && !load_dcard3)
            else $fatal(1, "DECIDE_D3 outputs wrong (expected no loads)");

        // Next DEAL_D3 (load_dcard3 asserted)
        @(posedge slow_clock); #1;
        assert(load_dcard3 && !load_pcard3)
            else $fatal(1, "DEAL_D3 outputs wrong (expected load_dcard3=1)");

        // Next CHECK_SCORE (no loads)
        @(posedge slow_clock); #1;
        assert(!load_pcard3 && !load_dcard3)
            else $fatal(1, "CHECK_SCORE after DEAL_D3 outputs wrong (expected no loads)");

        // Force a terminal outcome 
        pscore = 4'd7;
        dscore = 4'd6;

        @(posedge slow_clock); #1;
        assert(player_win_light && !dealer_win_light)
            else $fatal(1, "Expected PLAYER_WINS after CHECK_SCORE");

        // Reset between tests
        resetb = 1'b0;
        @(posedge slow_clock);
        @(posedge slow_clock);
        resetb = 1'b1;
        #1;

        // TEST 5: Player draws P3, Dealer does NOT draw (DECIDE_D3 -> CHECK_SCORE)
        // Example: pscore=4 (player draws), dscore=7 => dealer stands regardless.
        $display("\nTEST 5: DEAL_P3 -> DECIDE_D3 -> CHECK_SCORE (dealer stands)");

        pscore = 4'd4;   // player draws
        dscore = 4'd7;   // dealer stands
        pcard3 = 4'd2;   // doesn't matter here

        // Walk to CHECK_NAT
        @(posedge slow_clock); // S0
        @(posedge slow_clock); // S1
        @(posedge slow_clock); // S2
        @(posedge slow_clock); // CHECK_NAT

        // DEAL_P3
        @(posedge slow_clock); #1;
        assert(load_pcard3) else $fatal(1, "Expected load_pcard3 in DEAL_P3");

        // DECIDE_D3
        @(posedge slow_clock); #1;

        // Should go to CHECK_SCORE (no DEAL_D3 pulse)
        @(posedge slow_clock); #1;
        assert(!load_dcard3) else $fatal(1, "Dealer should not draw (load_dcard3 should be 0)");

        // Set outcome
        pscore = 4'd6;
        dscore = 4'd7;

        @(posedge slow_clock); #1;
        assert(!player_win_light && dealer_win_light)
            else $fatal(1, "Expected DEALER_WINS for this test");

        // Reset between tests
        resetb = 1'b0;
        @(posedge slow_clock);
        @(posedge slow_clock);
        resetb = 1'b1;
        #1;

        // TEST 6: Player stands (pscore=6/7), Dealer draws if dscore<=5
        // Example: pscore=6, dscore=5 => CHECK_NAT -> DEAL_D3 -> CHECK_SCORE
        $display("\nTEST 6: Player stands, Dealer draws (CHECK_NAT -> DEAL_D3)");

        pscore = 4'd6;   // player stands
        dscore = 4'd5;   // dealer draws
        pcard3 = 4'd0;   // irrelevant

        // Walk to CHECK_NAT
        @(posedge slow_clock); // S0
        @(posedge slow_clock); // S1
        @(posedge slow_clock); // S2
        @(posedge slow_clock); // CHECK_NAT

        // Should go directly to DEAL_D3
        @(posedge slow_clock); #1;
        assert(load_dcard3) else $fatal(1, "Expected load_dcard3 in DEAL_D3 when player stands and dealer draws");

        // Then CHECK_SCORE
        @(posedge slow_clock); #1;
        assert(!load_dcard3) else $fatal(1, "Expected no loads in CHECK_SCORE");

        // End with tie
        pscore = 4'd7;
        dscore = 4'd7;

        @(posedge slow_clock); #1;
        assert(player_win_light && dealer_win_light)
            else $fatal(1, "Expected TIE in this test");

        $display("\nAll statemachine tests passed!");
        $stop(0);
    end

endmodule
