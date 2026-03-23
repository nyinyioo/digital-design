`timescale 1ns/1ps
module tb_reuleaux();

    // --------------------------------------------------------
    // FSM Parameters
    // --------------------------------------------------------
    parameter  TOTAL_STATES      = 6;
    parameter  TOTAL_TRANSITIONS = 11;
    localparam TOTAL_COVERAGE    = TOTAL_STATES + TOTAL_TRANSITIONS;

    parameter CLEAR   = 3'd0,
              WAIT    = 3'd1,
              DRAW_C3 = 3'd2,
              DRAW_C1 = 3'd3,
              DRAW_C2 = 3'd4,
              DONE    = 3'd5;

    /*
        CLEAR   -> CLEAR   (pixel_done = 0)
        CLEAR   -> WAIT    (pixel_done = 1)
        WAIT    -> WAIT    (start = 0)
        WAIT    -> DRAW_C3 (start = 1)
        DRAW_C3 -> DRAW_C3 (~circle_done)
        DRAW_C3 -> DRAW_C1 (circle_done)
        DRAW_C1 -> DRAW_C1 (~circle_done)
        DRAW_C1 -> DRAW_C2 (circle_done)
        DRAW_C2 -> DRAW_C2 (~circle_done)
        DRAW_C2 -> DONE    (circle_done)
        DONE    -> WAIT    (~start)
        DONE    -> DONE    (start)
    */

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic clk, rst_n, start;
    logic [2:0] colour;
    logic [7:0] centre_x;
    logic [6:0] centre_y;
    logic [7:0] diameter;
    logic done;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;

    // --------------------------------------------------------
    // State probes
    // --------------------------------------------------------
    logic [2:0] state, next_state;
    assign state      = UUT.state;
    assign next_state = UUT.next_state;

    // intermediate signals
    integer cycle_count;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    reuleaux UUT(
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .centre_x(centre_x),
        .centre_y(centre_y),
        .diameter(diameter),
        .start(start),
        .done(done),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    // --------------------------------------------------------
    // Clock generation -- 20ns
    // --------------------------------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    // --------------------------------------------------------
    // Coverage variables
    // --------------------------------------------------------

    // State coverage
    logic visited_CLEAR;
    logic visited_WAIT;
    logic visited_DRAW_C3;
    logic visited_DRAW_C1;
    logic visited_DRAW_C2;
    logic visited_DONE;

    // Transition coverage
    logic transition_CLEAR_CLEAR;
    logic transition_CLEAR_WAIT;
    logic transition_WAIT_DRAW_C3;
    logic transition_DRAW_C3_DRAW_C3;
    logic transition_DRAW_C3_DRAW_C1;
    logic transition_DRAW_C1_DRAW_C1;
    logic transition_DRAW_C1_DRAW_C2;
    logic transition_DRAW_C2_DRAW_C2;
    logic transition_DRAW_C2_DONE;
    logic transition_DONE_WAIT;
    logic transition_DONE_DONE;

    // Coverage totals
    integer states_covered, transitions_covered;

    // --------------------------------------------------------
    // Coverage sampling -- clocked
    // --------------------------------------------------------
    always @(posedge clk) begin

        // State coverage
        case (state)
            CLEAR:   visited_CLEAR   = 1;
            WAIT:    visited_WAIT    = 1;
            DRAW_C3: visited_DRAW_C3 = 1;
            DRAW_C1: visited_DRAW_C1 = 1;
            DRAW_C2: visited_DRAW_C2 = 1;
            DONE:    visited_DONE    = 1;
        endcase

        // Transition coverage
        if (state == CLEAR   && next_state == CLEAR  ) transition_CLEAR_CLEAR     = 1;
        if (state == CLEAR   && next_state == WAIT   ) transition_CLEAR_WAIT      = 1;
        if (state == WAIT    && next_state == DRAW_C3) transition_WAIT_DRAW_C3    = 1;
        if (state == DRAW_C3 && next_state == DRAW_C3) transition_DRAW_C3_DRAW_C3 = 1;
        if (state == DRAW_C3 && next_state == DRAW_C1) transition_DRAW_C3_DRAW_C1 = 1;
        if (state == DRAW_C1 && next_state == DRAW_C1) transition_DRAW_C1_DRAW_C1 = 1;
        if (state == DRAW_C1 && next_state == DRAW_C2) transition_DRAW_C1_DRAW_C2 = 1;
        if (state == DRAW_C2 && next_state == DRAW_C2) transition_DRAW_C2_DRAW_C2 = 1;
        if (state == DRAW_C2 && next_state == DONE   ) transition_DRAW_C2_DONE    = 1;
        if (state == DONE    && next_state == WAIT   ) transition_DONE_WAIT       = 1;
        if (state == DONE    && next_state == DONE   ) transition_DONE_DONE       = 1;

    end

    // Coverage totals -- combinational
    always_comb begin

        states_covered      = visited_CLEAR   + visited_WAIT
                            + visited_DRAW_C3 + visited_DRAW_C1
                            + visited_DRAW_C2 + visited_DONE;

        transitions_covered = transition_CLEAR_CLEAR     + transition_CLEAR_WAIT
                            + transition_WAIT_DRAW_C3    + transition_DRAW_C3_DRAW_C3
                            + transition_DRAW_C3_DRAW_C1 + transition_DRAW_C1_DRAW_C1
                            + transition_DRAW_C1_DRAW_C2 + transition_DRAW_C2_DRAW_C2
                            + transition_DRAW_C2_DONE    + transition_DONE_WAIT
                            + transition_DONE_DONE;
    end

    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    initial begin
        $display("=== TB: Reuleaux Manual Coverage Tracking ===");

        // initialise coverage variables
        visited_CLEAR   = 0; visited_WAIT    = 0;
        visited_DRAW_C3 = 0; visited_DRAW_C1 = 0;
        visited_DRAW_C2 = 0; visited_DONE    = 0;

        transition_CLEAR_CLEAR     = 0; transition_CLEAR_WAIT      = 0;
        transition_WAIT_DRAW_C3    = 0; transition_DRAW_C3_DRAW_C3 = 0;
        transition_DRAW_C3_DRAW_C1 = 0; transition_DRAW_C1_DRAW_C1 = 0;
        transition_DRAW_C1_DRAW_C2 = 0; transition_DRAW_C2_DRAW_C2 = 0;
        transition_DRAW_C2_DONE    = 0; transition_DONE_WAIT       = 0;
        transition_DONE_DONE       = 0;

        // initialise inputs
        rst_n    = 1;
        start    = 0;
        colour   = 3'b010;
        centre_x = 8'd80;
        centre_y = 7'd60;
        diameter = 8'd40;

        // TEST 1: reset
        rst_n = 0;
        @(posedge clk); #1;
        assert(done == 1'b0)        else $error("TEST1 FAIL: done should be 0 on reset, got %0d", done);
        assert(vga_plot == 1'b1)    else $error("TEST1 FAIL: vga_plot should be 1 in CLEAR, got %0d", vga_plot);
        assert(vga_colour == 3'b0)  else $error("TEST1 FAIL: colour should be black in CLEAR, got %0d", vga_colour);
        assert(state == CLEAR)      else $error("TEST1 FAIL: state should be CLEAR, got %0d", state);
        assert(next_state == CLEAR) else $error("TEST1 FAIL: next_state should be CLEAR, got %0d", next_state);
        rst_n = 1;
        @(posedge clk); #1;

        // TEST 2: clear -> wait
        assert(state == CLEAR)      else $error("TEST2 FAIL: should be in CLEAR after reset, got %0d", state);
        assert(next_state == CLEAR) else $error("TEST2 FAIL: next_state should be CLEAR, got %0d", next_state);
        assert(vga_plot == 1'b1)    else $error("TEST2 FAIL: vga_plot should be 1 during CLEAR, got %0d", vga_plot);
        assert(vga_colour == 3'b0)  else $error("TEST2 FAIL: colour should be black during CLEAR, got %0d", vga_colour);

        cycle_count = 0;
        while (state !== WAIT) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if (cycle_count > 19210) begin
                $error("TEST2 FAIL: exceeded 19210 cycles, at cycle count: %0d", cycle_count);
                break;
            end
        end

        assert(cycle_count <= 19200) else $error("TEST2 FAIL: took %0d cycles, max is 19200", cycle_count);
        $display("TEST 2   [CLEAR -> WAIT]: completed in %0d cycles", cycle_count);

        assert(state == WAIT)      else $error("TEST2 FAIL: should be in WAIT after clear, got %0d", state);
        assert(next_state == WAIT) else $error("TEST2 FAIL: next_state should be WAIT, got %0d", next_state);
        assert(vga_plot == 1'b0)   else $error("TEST2 FAIL: vga_plot should be 0 in WAIT, got %0d", vga_plot);

        // TEST 3: wait -> DRAW_C3
        start = 1;
        @(posedge clk); #1;
        assert(state == DRAW_C3)      else $error("TEST3 FAIL: should be in DRAW_C3 after start, got %0d", state);
        assert(next_state == DRAW_C3) else $error("TEST3 FAIL: next_state should be DRAW_C3, got %0d", next_state);

        // TEST 4: signed arithmetic check (c1, c2, c3 coordinates)
        // centre=(80,60), diameter=40
        // c3_x = 80,       c3_y = 60 - (40*37>>6) = 60 - 23 = 37
        // c1_x = 80 + 20,  c1_y = 60 + (40*37>>7) = 60 + 11 = 71
        // c2_x = 80 - 20,  c2_y = 60 + (40*37>>7) = 60 + 11 = 71

        // TEST 5: DRAW_C3 -> DRAW_C3 (~circle_done)
        @(posedge clk); #1;
        assert(state == DRAW_C3)      else $error("TEST5 FAIL: should stay in DRAW_C3, got %0d", state);
        assert(next_state == DRAW_C3) else $error("TEST5 FAIL: next_state should be DRAW_C3, got %0d", next_state);

        // TEST 6: DRAW_C3 -> DRAW_C1 (circle_done)
        while (state !== DRAW_C1) begin
            @(posedge clk); #1;
            if (state == DONE) begin
                $error("TEST6 FAIL: state should be DRAW_C1, got %0d", state);
                break;
            end
        end
        
        assert(state == DRAW_C1)      else $error("TEST6 FAIL: should be in DRAW_C1, got %0d", state);
        assert(next_state == DRAW_C1) else $error("TEST6 FAIL: next_state should be DRAW_C1, got %0d", next_state);
        $display("TEST 6   [DRAW_C3 -> DRAW_C1]: pass");

        // TEST 7: DRAW_C1 -> DRAW_C1 (~circle_done)
        @(posedge clk); #1;
        assert(state == DRAW_C1)      else $error("TEST7 FAIL: should stay in DRAW_C1, got %0d", state);
        assert(next_state == DRAW_C1) else $error("TEST7 FAIL: next_state should be DRAW_C1, got %0d", next_state);

        // TEST 8: DRAW_C1 -> DRAW_C2 (circle_done)
        while (state !== DRAW_C2) begin
            @(posedge clk); #1;
            if (state == DONE) begin
                $error("TEST8 FAIL: state should be DRAW_C2, got %0d", state);
                break;
            end
        end
        assert(state == DRAW_C2)      else $error("TEST8 FAIL: should be in DRAW_C2, got %0d", state);
        assert(next_state == DRAW_C2) else $error("TEST8 FAIL: next_state should be DRAW_C2, got %0d", next_state);
        $display("TEST 8   [DRAW_C1 -> DRAW_C2]: pass");

        // TEST 9: DRAW_C2 -> DRAW_C2 (~circle_done)
        @(posedge clk); #1;
        assert(state == DRAW_C2)      else $error("TEST9 FAIL: should stay in DRAW_C2, got %0d", state);
        assert(next_state == DRAW_C2) else $error("TEST9 FAIL: next_state should be DRAW_C2, got %0d", next_state);

        // TEST 10: DRAW_C2 -> DONE (circle_done)
        while (state !== DONE) begin
            @(posedge clk); #1;
        end
        assert(state == DONE) else $error("TEST10 FAIL: should be in DONE, got %0d", state);
        assert(done == 1'b1)  else $error("TEST10 FAIL: done should be 1, got %0d", done);
        $display("TEST 10  [DRAW_C2 -> DONE]: pass");

        // TEST 11: DONE -> DONE 
        @(posedge clk); #1;
        assert(state == DONE)      else $error("TEST11 FAIL: should stay in DONE with start=1, got %0d", state);
        assert(next_state == DONE) else $error("TEST11 FAIL: next_state should be DONE, got %0d", next_state);
        assert(done == 1'b1)       else $error("TEST11 FAIL: done should be 1, got %0d", done);

        // TEST 12: DONE -> WAIT (start deasserted)
        start = 0;
        @(posedge clk); #1;   
        assert(state == WAIT)      else $error("TEST12 FAIL: should be in WAIT, got %0d", state);
        assert(next_state == WAIT) else $error("TEST12 FAIL: next_state should stay WAIT, got %0d", next_state);
        assert(done == 1'b0)       else $error("TEST12 FAIL: done should be 0, got %0d", done);
        assert(vga_plot == 1'b0)   else $error("TEST12 FAIL: vga_plot should be 0 in WAIT, got %0d", vga_plot);
        
        // TEST 13: cycle count
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        start = 0;

        while (state !== WAIT) begin
            @(posedge clk); #1;
        end

        cycle_count = 0;
        start = 1;
        @(posedge clk); #1;
        assert(state == DRAW_C3) else $error("TEST12 FAIL: should be in DRAW_C3, got %0d", state);

        while (done !== 1'b1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if (cycle_count > 10000) begin
                $error("TEST12 FAIL: exceeded cycle budget at cycle %0d", cycle_count);
                break;
            end
        end

        $display("TEST 12  [DRAW_C3 -> DONE cycle count]: completed in %0d cycles", cycle_count);

        // --------------------------------------------------------
        // Coverage report
        // --------------------------------------------------------
        $display("");
        $display("=== Manual Coverage Report ===");
        $display("");
        $display("--- State Coverage ---");
        $display("CLEAR   visited: %0b", visited_CLEAR);
        $display("WAIT    visited: %0b", visited_WAIT);
        $display("DRAW_C3 visited: %0b", visited_DRAW_C3);
        $display("DRAW_C1 visited: %0b", visited_DRAW_C1);
        $display("DRAW_C2 visited: %0b", visited_DRAW_C2);
        $display("DONE    visited: %0b", visited_DONE);
        $display("");
        $display("--- Transition Coverage ---");
        $display("CLEAR   -> CLEAR   : %0b", transition_CLEAR_CLEAR);
        $display("CLEAR   -> WAIT    : %0b", transition_CLEAR_WAIT);
        $display("WAIT    -> DRAW_C3 : %0b", transition_WAIT_DRAW_C3);
        $display("DRAW_C3 -> DRAW_C3 : %0b", transition_DRAW_C3_DRAW_C3);
        $display("DRAW_C3 -> DRAW_C1 : %0b", transition_DRAW_C3_DRAW_C1);
        $display("DRAW_C1 -> DRAW_C1 : %0b", transition_DRAW_C1_DRAW_C1);
        $display("DRAW_C1 -> DRAW_C2 : %0b", transition_DRAW_C1_DRAW_C2);
        $display("DRAW_C2 -> DRAW_C2 : %0b", transition_DRAW_C2_DRAW_C2);
        $display("DRAW_C2 -> DONE    : %0b", transition_DRAW_C2_DONE);
        $display("DONE    -> WAIT    : %0b", transition_DONE_WAIT);
        $display("DONE    -> DONE    : %0b", transition_DONE_DONE);
        $display("");
        $display("State Coverage:      %0d / %0d", states_covered, TOTAL_STATES);
        $display("Transition Coverage: %0d / %0d", transitions_covered, TOTAL_TRANSITIONS);
        $display("Overall Coverage:    %0d / %0d = %.1f%%",
            states_covered + transitions_covered, TOTAL_COVERAGE,
            100.0 * (states_covered + transitions_covered) / TOTAL_COVERAGE);
        $display("==============================");

        $finish(0);
    end

endmodule: tb_reuleaux