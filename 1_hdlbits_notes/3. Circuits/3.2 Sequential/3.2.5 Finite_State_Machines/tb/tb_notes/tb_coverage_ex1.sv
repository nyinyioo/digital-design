  `timescale 1ns/1ps

// ============================================================
// TB1 — Manual Coverage Tracking
// FSM: 2 states (A, B), 1 input (in), 1 output (out)
//
// State B (out=1): reset -> B, stays B on in=1, goes A on in=0
// State A (out=0): stays A on in=1, goes B on in=0
// ============================================================

module tb_coverage_ex1;

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    reg  clk, areset, in;
    wire out;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    top_module dut (
        .clk    (clk),
        .areset (areset),
        .in     (in),
        .out    (out)
    );

    // --------------------------------------------------------
    // Clock generation — 10ns period
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // State encoding (mirror DUT encoding for readability)
    // --------------------------------------------------------
    parameter A = 1'b0,
              B = 1'b1;

    // --------------------------------------------------------
    // Coverage variables
    // --------------------------------------------------------

    // State coverage
    bit visited_A;
    bit visited_B;

    // Transition coverage
    bit trans_B_to_B;   // B -> B  (in=1)
    bit trans_B_to_A;   // B -> A  (in=0)
    bit trans_A_to_A;   // A -> A  (in=1)
    bit trans_A_to_B;   // A -> B  (in=0)

    // prev_state for transition tracking
    // (next_state is combinational and can glitch — prev_state
    //  confirms the transition actually committed through the flop)
    reg prev_state;

    // --------------------------------------------------------
    // Coverage sampling — runs every clock edge
    // --------------------------------------------------------
    always @(posedge clk) begin

        // --- State coverage ---
        case (out)
            1'b1: visited_B = 1;
            1'b0: visited_A = 1;
        endcase

        // --- Transition coverage ---
        // prev_state holds the state from the previous cycle
        if (prev_state == B && out == B) trans_B_to_B = 1;
        if (prev_state == B && out == A) trans_B_to_A = 1;
        if (prev_state == A && out == A) trans_A_to_A = 1;
        if (prev_state == A && out == B) trans_A_to_B = 1;

        // Register current state for next cycle comparison
        prev_state <= out;
    end

    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    integer i;

    initial begin
        $display("=== TB1: Manual Coverage Tracking ===");

        // Apply reset
        areset = 1; in = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        areset = 0;

        // Drive random stimulus to hit all states and transitions
        for (i = 0; i < 30; i = i + 1) begin
            in = $random % 2;
            @(posedge clk); #1;
        end

        // Explicitly force each transition to guarantee coverage
        // B -> A : drive in=0 while in state B
        areset = 1; @(posedge clk); #1; areset = 0;  // go to B
        in = 0; @(posedge clk); #1;                   // B -> A

        // A -> B : drive in=0 while in state A
        in = 0; @(posedge clk); #1;                   // A -> B

        // B -> B : drive in=1 while in state B
        in = 1; @(posedge clk); #1;                   // B -> B

        // A -> A : drive in=1 while in state A
        in = 0; @(posedge clk); #1;                   // B -> A
        in = 1; @(posedge clk); #1;                   // A -> A

        // Let simulation settle
        repeat(5) @(posedge clk);

        $finish;
    end

    // --------------------------------------------------------
    // Final coverage report
    // --------------------------------------------------------
    final begin
        $display("");
        $display("=== Manual Coverage Report ===");
        $display("--- State Coverage ---");
        $display("  State B visited : %0b", visited_B);
        $display("  State A visited : %0b", visited_A);
        $display("--- Transition Coverage ---");
        $display("  B -> B          : %0b", trans_B_to_B);
        $display("  B -> A          : %0b", trans_B_to_A);
        $display("  A -> A          : %0b", trans_A_to_A);
        $display("  A -> B          : %0b", trans_A_to_B);
        $display("");

        // Compute manual coverage percentage
        begin
            integer states_hit, trans_hit;
            states_hit = visited_A + visited_B;
            trans_hit  = trans_B_to_B + trans_B_to_A +
                         trans_A_to_A + trans_A_to_B;
            $display("  States     : %0d / 2", states_hit);
            $display("  Transitions: %0d / 4", trans_hit);
            $display("  Overall    : %0d / 6 = %.1f%%",
                     states_hit + trans_hit,
                     100.0 * (states_hit + trans_hit) / 6.0);
        end
        $display("==============================");
    end

endmodule