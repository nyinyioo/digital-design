
`timescale 1ps/1ps
module tb_fsm_serial();

    // signals
    logic clk, in, reset;
    logic done;

    // instantiate
    top_module UUT(
        .clk(clk),
        .in(in),
        .reset(reset),
        .done(done)
    );

    // probe internals
    logic [2:0] state, next_state;
    parameter WAIT = 0, START = 1, DATA = 2, STOP = 3, ERR = 4;

    assign state      = UUT.state;
    assign next_state = UUT.next_state;

    // coverage variables
    logic [4:0] states_covered;      // 5 states
    logic [8:0] transitions_covered; // 7 transitions
    integer x, y, m, n;

    // -------------------------------------------------------------------------
    // coverage functions

    function automatic logic [4:0] one_hot_state(input logic [2:0] s);
        one_hot_state = 5'b00000;
        case(s)
            WAIT:  one_hot_state[4] = 1'b1;
            START: one_hot_state[3] = 1'b1;
            DATA:  one_hot_state[2] = 1'b1;
            STOP:  one_hot_state[1] = 1'b1;
            ERR:   one_hot_state[0] = 1'b1;
        endcase
    endfunction

    function automatic int state_coverage(input logic [3:0] v);
        integer i;
        state_coverage = 0;
        for(i = 0; i < 5; i++)
            state_coverage += v[i];
    endfunction

    function automatic logic [8:0] one_hot_transition(
        input logic [2:0] s,
        input logic [2:0] ns
    );
        one_hot_transition = 9'b000000000;
        case({s, ns})
            {WAIT,  START}: one_hot_transition[8] = 1'b1;
            {WAIT,  WAIT}:  one_hot_transition[7] = 1'b1;
            {START, DATA}:  one_hot_transition[6] = 1'b1;
            {DATA,  DATA}:  one_hot_transition[5] = 1'b1;
            {DATA,  STOP}:  one_hot_transition[4] = 1'b1;
            {DATA,  ERR}:   one_hot_transition[3] = 1'b1;
            {STOP,  WAIT}:  one_hot_transition[2] = 1'b1;
            {STOP,  START}: one_hot_transition[1] = 1'b1;
            {ERR,   WAIT}:  one_hot_transition[0] = 1'b1;
        endcase
    endfunction

    function automatic int transition_coverage(input logic [8:0] v);
        integer i;
        transition_coverage = 0;
        for(i = 0; i < 9; i++)
            transition_coverage += v[i];
    endfunction

    // -------------------------------------------------------------------------

    task send_bit(input logic b);
        logic [1:0] cur_state;
        logic [1:0] cur_next;
        in = b;              // set in FIRST
        #1;                  // let combinational next_state settle
        cur_state = state;
        cur_next  = next_state;  // now sample after in is stable
        @(posedge clk); #1;
        states_covered      |= one_hot_state(state);
        transitions_covered |= one_hot_transition(cur_state, cur_next);
    endtask

    task send_byte(input logic [7:0] data);
        send_bit(0);                          // start bit
        for(int i = 0; i < 8; i++)
            send_bit(data[i]);                // 8 data bits LSB first
        send_bit(1);                          // stop bit
    endtask

    task print_coverage();
        x = state_coverage(states_covered);
        y = 5;
        m = transition_coverage(transitions_covered);
        n = 9;
        $display("-------------------------------------");
        $display("COVERAGE REPORT");
        $display("States:      %0d/%0d", x, y);
        $display("Transitions: %0d/%0d", m, n);
        $display("Overall:     %0d/%0d (%.1f%%)", x+m, y+n, 100.0*(x+m)/(y+n));
        $display("-------------------------------------");
    endtask

    // -------------------------------------------------------------------------
    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // testbench
   initial begin
        // initialize coverage
        states_covered      = 4'b0000;
        transitions_covered = 7'b0000000;

        // initialize
        in    = 1;
        reset = 1;
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        reset = 0;

        // TEST 1: reset → WAIT
        assert(state == WAIT)      else $fatal("TEST1 FAIL: should be WAIT, got %0d", state);
        assert(next_state == WAIT) else $fatal("TEST1 FAIL: next should be WAIT, got %0d", next_state);
        assert(done == 0)          else $fatal("TEST1 FAIL: done should be 0");
        $display("TEST1 PASS: reset → WAIT");

        // TEST 2: WAIT → START on in=0
        in = 0; #1;
        assert(next_state == START) else $fatal("TEST2 FAIL: next should be START, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == START) else $fatal("TEST2 FAIL: should be START, got %0d", state);
        $display("TEST2 PASS: WAIT → START");

        // TEST 3: START → DATA
        in = 1; #1;
        assert(next_state == DATA) else $fatal("TEST3 FAIL: next should be DATA, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == DATA) else $fatal("TEST3 FAIL: should be DATA, got %0d", state);
        $display("TEST3 PASS: START → DATA");

        // TEST 4: DATA self loop x7 (count 0→6)
        repeat(7) begin
            in = 1; #1;
            assert(next_state == DATA) else $fatal("TEST4 FAIL: should stay DATA, got %0d", next_state);
            transitions_covered |= one_hot_transition(state, next_state);
            @(posedge clk); #1;
            states_covered |= one_hot_state(state);
            assert(state == DATA) else $fatal("TEST4 FAIL: should be DATA, got %0d", state);
        end
        $display("TEST4 PASS: DATA self-loop x7");

        // TEST 5: DATA → STOP on count=7
        in = 1; #1;
        assert(next_state == STOP) else $fatal("TEST5 FAIL: next should be STOP, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == STOP) else $fatal("TEST5 FAIL: should be STOP, got %0d", state);
        assert(done == 1)     else $fatal("TEST5 FAIL: done should be 1");
        $display("TEST5 PASS: DATA → STOP, done=1");

        // TEST 6: STOP → WAIT on in=1
        in = 1; #1;
        assert(next_state == WAIT) else $fatal("TEST6 FAIL: next should be WAIT, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == WAIT) else $fatal("TEST6 FAIL: should be WAIT, got %0d", state);
        assert(done == 0)     else $fatal("TEST6 FAIL: done should drop");
        $display("TEST6 PASS: STOP → WAIT, done drops");

        // TEST 7: WAIT → WAIT on in=1
        in = 1; #1;
        assert(next_state == WAIT) else $fatal("TEST7 FAIL: next should be WAIT, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == WAIT) else $fatal("TEST7 FAIL: should stay WAIT, got %0d", state);
        $display("TEST7 PASS: WAIT → WAIT on in=1");

        // TEST 8: invalid stop → STOP → START error recovery
        send_bit(0);                    // WAIT→START
        for(int i = 0; i < 7; i++)
            send_bit(1);               // DATA x7
        // count==7, send in=0 → DATA→ERR
        in = 0; #1;
        assert(next_state == ERR) else $fatal("TEST8 FAIL: next should be ERR, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == ERR) else $fatal("TEST8 FAIL: should be ERR, got %0d", state);
        assert(done == 0)    else $fatal("TEST8 FAIL: done should be 0");
        $display("TEST8 PASS: DATA → ERR on invalid stop");

        // TEST 8b: ERR → WAIT on in=1
        in = 1; #1;
        assert(next_state == WAIT) else $fatal("TEST8b FAIL: next should be WAIT, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        states_covered |= one_hot_state(state);
        assert(state == WAIT) else $fatal("TEST8b FAIL: should be WAIT, got %0d", state);
        $display("TEST8b PASS: ERR → WAIT");

        // TEST 8c: ERR → ERR on in=0
        send_bit(0);                    // WAIT→START
        for(int i = 0; i < 7; i++)
            send_bit(1);
        in = 0; #1;                     // DATA→ERR
        @(posedge clk); #1;
        in = 0; #1;                     // ERR→ERR
        assert(next_state == ERR) else $fatal("TEST8c FAIL: should stay ERR, got %0d", next_state);
        transitions_covered |= one_hot_transition(state, next_state);
        @(posedge clk); #1;
        assert(state == ERR) else $fatal("TEST8c FAIL: should be ERR, got %0d", state);
        $display("TEST8c PASS: ERR → ERR on in=0");
        print_coverage();
        $display("ALL TESTS PASSED");
        $finish;

        
    end
endmodule


