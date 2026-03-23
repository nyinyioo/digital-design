`timescale 1ns/1ps
module tb_fillscreen();
    // --------------------------------------------------------
    // FSM Parameters
    // --------------------------------------------------------
    parameter  TOTAL_STATES      = 4;
    parameter  TOTAL_TRANSITIONS = 7;
    localparam TOTAL_COVERAGE    = TOTAL_STATES + TOTAL_TRANSITIONS;

    parameter CLEAR = 2'd0,
              WAIT  = 2'd1,
              PLOT  = 2'd2,
              DONE  = 2'd3;

    /*
        CLEAR -> CLEAR (pixel_done = 0)
        CLEAR -> WAIT  (pixel_done = 1)
        WAIT  -> WAIT  (start = 0)
        WAIT  -> PLOT  (start = 1)
        PLOT  -> PLOT  (start = 1 && pixel_done = 0)
        PLOT  -> WAIT  (~start && ~pixel_done)
        PLOT  -> DONE  (pixel_done = 1)
        DONE  -> WAIT  (~start)
        DONE  -> PLOT  (start)
    */

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic clk, rst_n, start;
    logic [2:0] colour;
    logic done;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;
    
    // --------------------------------------------------------
    // State probes
    // --------------------------------------------------------
    logic [1:0] state, next_state;
    assign state      = UUT.state;
    assign next_state = UUT.next_state;

    //intermediate signals
    integer cycle_count;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    fillscreen UUT(
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .start(start),
        .done(done),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    // --------------------------------------------------------
    // Clock generation — 20ns
    // --------------------------------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    // --------------------------------------------------------
    // Coverage variables
    // --------------------------------------------------------
    // State coverage
    logic visited_CLEAR;
    logic visited_WAIT;
    logic visited_PLOT;
    logic visited_DONE;

    // Transition coverage
    logic transition_CLEAR_WAIT;
    logic transition_WAIT_PLOT; 
    logic transition_PLOT_DONE; 
    logic transition_DONE_WAIT; 
    logic transition_PLOT_WAIT; 
    logic transition_DONE_PLOT;
    logic transition_PLOT_PLOT;

    // Coverage totals
    integer states_covered, transitions_covered;

    // --------------------------------------------------------
    // Coverage sampling — clocked
    // --------------------------------------------------------
    always @(posedge clk) begin

        // State coverage
        case (state)
            CLEAR: visited_CLEAR = 1;
            WAIT:  visited_WAIT  = 1;
            PLOT:  visited_PLOT  = 1;
            DONE:  visited_DONE  = 1;
        endcase

        // Transition coverage
        if (state == CLEAR && next_state == WAIT) transition_CLEAR_WAIT = 1;
        if (state == WAIT  && next_state == PLOT) transition_WAIT_PLOT  = 1;
        if (state == PLOT  && next_state == DONE) transition_PLOT_DONE  = 1;
        if (state == DONE  && next_state == WAIT) transition_DONE_WAIT  = 1;
        if (state == PLOT  && next_state == WAIT) transition_PLOT_WAIT  = 1;
        if (state == DONE  && next_state == PLOT) transition_DONE_PLOT  = 1;
        if (state == PLOT  && next_state == PLOT) transition_PLOT_PLOT  = 1;

    end

    // Coverage totals — combinational
    always_comb begin

        states_covered      = visited_CLEAR + visited_WAIT
                            + visited_PLOT  + visited_DONE;

        transitions_covered = transition_CLEAR_WAIT + transition_WAIT_PLOT
                            + transition_PLOT_DONE  + transition_DONE_WAIT
                            + transition_PLOT_WAIT  + transition_DONE_PLOT
                            + transition_PLOT_PLOT;
    end

    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    initial begin
        $display("=== TB: Fillscreen Manual Coverage Tracking ===");

        // initialise coverage variables
        visited_CLEAR = 0; visited_WAIT = 0;
        visited_PLOT  = 0; visited_DONE = 0;

        transition_CLEAR_WAIT = 0; transition_WAIT_PLOT = 0;
        transition_PLOT_DONE  = 0; transition_DONE_WAIT = 0;
        transition_PLOT_WAIT  = 0; transition_DONE_PLOT = 0;
        transition_PLOT_PLOT  = 0;

        // initialise inputs
        rst_n  = 1;
        start  = 0;
        colour = 3'b0;

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
        assert(vga_plot == 1'b1)    else $error("TEST2 FAIL: vga_plot should be 1 during CLEAR, got %0d", vga_plot);
        assert(vga_colour == 3'b0)  else $error("TEST2 FAIL: colour should be black during CLEAR, got %0d", vga_colour);
        assert(next_state == CLEAR) else $error("TEST2 FAIL: next_state should be CLEAR, got %0d", next_state);

        cycle_count = 0;
        while(state !== WAIT) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if(cycle_count > 19210) begin
                $error("TEST2 FAIL: exceeded 19210 cycles, at cycle count: %0d", cycle_count);
                break;
            end
        end

        assert(cycle_count <= 19200) else $error("TEST2 FAIL: took %0d cycles, max is 19200", cycle_count);
        $display("TEST 2   [CLEAR -> WAIT]: completed in %0d cycles", cycle_count);

        assert(state == WAIT)      else $error("TEST2 FAIL: should be in WAIT after clear, got %0d", state);
        assert(next_state == WAIT) else $error("TEST2 FAIL: next_state should be WAIT, got %0d", next_state);
        assert(vga_plot == 1'b0)   else $error("TEST2 FAIL: vga_plot should be 0 in WAIT, got %0d", vga_plot);

        // TEST 3: wait -> plot
        start = 1;
        @(posedge clk); #1;
        assert(state == PLOT)      else $error("TEST3 FAIL: should be in PLOT after start, got %0d", state);
        assert(next_state == PLOT) else $error("TEST3 FAIL: next_state should be PLOT, got %0d", next_state);
        assert(vga_plot == 1'b1)   else $error("TEST3 FAIL: vga_plot should be 1 in PLOT, got %0d", vga_plot);
        assert(vga_x == 8'd0)      else $error("TEST3 FAIL: vga_x should start at 0, got %0d", vga_x);
        assert(vga_y == 7'd0)      else $error("TEST3 FAIL: vga_y should start at 0, got %0d", vga_y);

        // TEST 4: correct colour
        assert(vga_colour == 3'd0) else $error("TEST4 FAIL: x=0 colour should be 0, got %0d", vga_colour);
        repeat(960) @(posedge clk); #1;
        assert(vga_x == 8'd8)      else $error("TEST4 FAIL: x should be 8, got %0d", vga_x);
        assert(vga_colour == 3'd0) else $error("TEST4 FAIL: x=8 colour should wrap to 0, got %0d", vga_colour);
        assert(state == PLOT)      else $error("TEST4 FAIL: should still be in PLOT, got %0d", state);
        assert(next_state == PLOT) else $error("TEST4 FAIL: next_state should still be PLOT, got %0d", next_state);

        // TEST 5: counter
        repeat(119) @(posedge clk); #1;
        assert(vga_y == 7'd119)    else $error("TEST5 FAIL: y should be 119 at end of column, got %0d", vga_y);
        assert(vga_x == 8'd8)      else $error("TEST5 FAIL: x should still be 8, got %0d", vga_x);
        assert(state == PLOT)      else $error("TEST5 FAIL: should still be in PLOT, got %0d", state);
        assert(next_state == PLOT) else $error("TEST5 FAIL: next_state should be PLOT, got %0d", next_state);
        @(posedge clk); #1;
        assert(vga_y == 7'd0)      else $error("TEST5 FAIL: y should wrap to 0, got %0d", vga_y);
        assert(vga_x == 8'd9)      else $error("TEST5 FAIL: x should increment to 9, got %0d", vga_x);

        // TEST 6: plot -> done
        repeat(18119) @(posedge clk); #1;
        assert(vga_x == 8'd159)    else $error("TEST6 FAIL: x should be 159, got %0d", vga_x);
        assert(vga_y == 7'd119)    else $error("TEST6 FAIL: y should be 119, got %0d", vga_y);
        assert(state == PLOT)      else $error("TEST6 FAIL: should still be in PLOT, got %0d", state);
        assert(next_state == DONE) else $error("TEST6 FAIL: next_state should be DONE, got %0d", next_state);

        // TEST 7: done -> wait
        start = 0;
        @(posedge clk); #1;
        assert(next_state == WAIT) else $error("TEST7 FAIL: next_state should be WAIT after ~start, got %0d", next_state);
        @(posedge clk); #1;
        assert(state == WAIT)      else $error("TEST7 FAIL: should be in WAIT, got %0d", state);
        assert(next_state == WAIT) else $error("TEST7 FAIL: next_state should stay WAIT, got %0d", next_state);
        assert(done == 1'b0)       else $error("TEST7 FAIL: done should be 0, got %0d", done);
        assert(vga_plot == 1'b0)   else $error("TEST7 FAIL: vga_plot should be 0, got %0d", vga_plot);

        // TEST 8: wait -> plot, count cycles until done
        cycle_count = 0;
        start = 1;
        @(posedge clk); #1;
        assert(state == PLOT) else $error("TEST8 FAIL: should be in PLOT, got %0d", state);

        while(done !== 1'b1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if(cycle_count > 19210) begin
                $error("TEST8 FAIL: exceeded 19210 cycles, at cycle count: %0d", cycle_count);
                break;
            end
        end

        assert(cycle_count <= 19210) else $error("TEST8 FAIL: took %0d cycles, max is 19210", cycle_count);
        $display("TEST 8   [WAIT -> PLOT -> DONE]: completed in %0d cycles", cycle_count);
        assert(state == DONE) else $error("TEST8 FAIL: should be in DONE, got %0d", state);
        assert(done == 1'b1)  else $error("TEST8 FAIL: done should be 1, got %0d", done);

        // TEST 9: done -> plot, count cycles until done
        cycle_count = 0;
        start = 1;
        @(posedge clk); #1;
        assert(state == PLOT)      else $error("TEST9 FAIL: should be in PLOT after start, got %0d", state);
        assert(next_state == PLOT) else $error("TEST9 FAIL: next_state should be PLOT, got %0d", next_state);

        while(done !== 1'b1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if(cycle_count > 19210) begin
                $error("TEST9 FAIL: exceeded 19210 cycles, at cycle count: %0d", cycle_count);
                break;
            end
        end

        assert(cycle_count <= 19210) else $error("TEST9 FAIL: took %0d cycles, max is 19210", cycle_count);
        $display("TEST 9   [DONE -> PLOT -> DONE]: completed in %0d cycles", cycle_count);
        assert(done == 1'b1) else $error("TEST9 FAIL: done should be 1, got %0d", done);


        // TEST 10: plot -> wait (deassert start mid-fill)
        start = 1;
        @(posedge clk); #1;
        assert(state == PLOT) else $error("TEST10 FAIL: should be in PLOT, got %0d", state);

        repeat(100) @(posedge clk); #1;   // mid fill screen
        start = 0;                        // deassert before pixel_done
        @(posedge clk); #1;
        assert(state == WAIT) else $error("TEST10 FAIL: should transition to WAIT, got %0d", state);

        // --------------------------------------------------------
        // Coverage report
        // --------------------------------------------------------
        $display("");
        $display("=== Manual Coverage Report ===");
        $display("");
        $display("--- State Coverage ---");
        $display("CLEAR visited: %0b", visited_CLEAR);
        $display("WAIT  visited: %0b", visited_WAIT);
        $display("PLOT  visited: %0b", visited_PLOT);
        $display("DONE  visited: %0b", visited_DONE);
        $display("");
        $display("--- Transition Coverage ---");
        $display("CLEAR -> WAIT : %0b", transition_CLEAR_WAIT);
        $display("WAIT  -> PLOT : %0b", transition_WAIT_PLOT);
        $display("PLOT  -> DONE : %0b", transition_PLOT_DONE);
        $display("DONE  -> WAIT : %0b", transition_DONE_WAIT);
        $display("PLOT  -> WAIT : %0b", transition_PLOT_WAIT);
        $display("DONE  -> PLOT : %0b", transition_DONE_PLOT);
        $display("PLOT  -> PLOT : %0b", transition_PLOT_PLOT);
        $display("");
        $display("State Coverage:      %0d / %0d", states_covered, TOTAL_STATES);
        $display("Transition Coverage: %0d / %0d", transitions_covered, TOTAL_TRANSITIONS);
        $display("Overall Coverage:    %0d / %0d = %.1f%%",
            states_covered + transitions_covered, TOTAL_COVERAGE,
            100.0 * (states_covered + transitions_covered) / TOTAL_COVERAGE);
        $display("==============================");

        $finish(0);
    end

endmodule: tb_fillscreen