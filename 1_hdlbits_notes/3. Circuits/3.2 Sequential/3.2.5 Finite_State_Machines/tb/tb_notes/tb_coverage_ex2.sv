`timescale 1ns/1ps

// ============================================================
// TB2 — Automatic Coverage with Covergroups
// FSM: 2 states (A, B), 1 input (in), 1 output (out)
//
// State B (out=1): reset -> B, stays B on in=1, goes A on in=0
// State A (out=0): stays A on in=1, goes B on in=0
//
// Note: The covergroup => transition operator internally tracks
// consecutive sampled values — equivalent to what prev_state
// does manually in tb_coverage_ex1.sv
// ============================================================

module tb_coverage_ex2;

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
    // State encoding
    // --------------------------------------------------------
    parameter A = 1'b0,
              B = 1'b1;

    // --------------------------------------------------------
    // Covergroup — sampled automatically at every posedge clk
    //
    // cp_state    : checks every state is visited
    // cp_trans    : checks every transition is taken
    //               => operator tracks prev->current automatically
    // --------------------------------------------------------
    covergroup fsm_cg @(posedge clk);

        // State coverage
        cp_state: coverpoint out {
            bins state_B = {1'b1};   // out=1 means in state B
            bins state_A = {1'b0};   // out=0 means in state A
        }

        // Transition coverage
        // => samples consecutive clock-edge values of out
        // (no need for prev_state — the tool handles it)
        cp_trans: coverpoint out {
            bins B_to_B = (1'b1 => 1'b1);   // B stays B (in=1)
            bins B_to_A = (1'b1 => 1'b0);   // B -> A    (in=0)
            bins A_to_A = (1'b0 => 1'b0);   // A stays A (in=1)
            bins A_to_B = (1'b0 => 1'b1);   // A -> B    (in=0)
        }

    endgroup

    // Instantiate covergroup
    fsm_cg cg_inst = new();

    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    integer i;

    initial begin
        $display("=== TB2: Automatic Covergroup Coverage ===");

        // Apply reset
        areset = 1; in = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        areset = 0;

        // Drive random stimulus
        for (i = 0; i < 30; i = i + 1) begin
            in = $random % 2;
            @(posedge clk); #1;
        end

        // Explicitly force each transition to guarantee 100% coverage
        // B -> A
        areset = 1; @(posedge clk); #1; areset = 0;
        in = 0; @(posedge clk); #1;

        // A -> B
        in = 0; @(posedge clk); #1;

        // B -> B
        in = 1; @(posedge clk); #1;

        // A -> A
        in = 0; @(posedge clk); #1;
        in = 1; @(posedge clk); #1;

        // Let simulation settle
        repeat(5) @(posedge clk);

        $finish;
    end

    // --------------------------------------------------------
    // Final coverage report
    // --------------------------------------------------------
    final begin
        $display("");
        $display("=== Covergroup Report ===");
        $display("  cp_state  coverage : %.2f%%", cg_inst.cp_state.get_coverage());
        $display("  cp_trans  coverage : %.2f%%", cg_inst.cp_trans.get_coverage());
        $display("  Overall   coverage : %.2f%%", cg_inst.get_coverage());
        $display("=========================");
    end

endmodule