# Functional Coverage for FSM Verification

**Goal:** Achieve 100% functional coverage of an FSM.

---

## Coverage Metrics

1. **State Coverage**
   - Ensure every FSM state is visited during simulation.

2. **Transition Coverage**
   - Ensure every valid state transition occurs at least once.

---

## Example (Generic FSM)

- **States:** N states → `ceil(log2(N))` bits
- **Transitions:** M valid transitions

| From    | To      | Condition   |
|---------|---------|-------------|
| STATE_A | STATE_B | condition_1 |
| STATE_A | STATE_A | condition_2 |
| STATE_B | STATE_C | condition_3 |
| STATE_C | STATE_D | condition_4 |
| STATE_C | STATE_E | condition_5 |
| STATE_D | STATE_A | condition_6 |
| STATE_D | STATE_B | condition_7 |
| STATE_E | STATE_A | condition_8 |
| STATE_E | STATE_E | condition_9 |

---

## Coverage Formula

```
Overall Coverage = (states_covered + transitions_covered)
                 / (total_states   + total_transitions)
```

---

## `next_state` vs `prev_state`

These two signals serve **different roles** and live in different places:

| Signal       | Lives in     | Purpose                                             |
|--------------|--------------|-----------------------------------------------------|
| `next_state` | Design (DUT) | Combinational logic — drives what state comes next  |
| `prev_state` | Testbench    | Registered — confirms a transition actually committed |

```systemverilog
// DESIGN — next_state is essential here (combinational block)
always_comb begin
    case (state)
        STATE_A: next_state = x ? STATE_B : STATE_A;
        STATE_B: next_state = y ? STATE_C : STATE_B;
        // ...
    endcase
end

// TESTBENCH — prev_state used for transition coverage (sequential block)
always @(posedge clk) begin
    prev_state <= state; // register current state, readable next cycle

    // Transition committed? Check what just happened
    if (prev_state == STATE_A && state == STATE_B) trans_A_to_B = 1;
    if (prev_state == STATE_B && state == STATE_C) trans_B_to_C = 1;
end
```

> **Why not use `next_state` for coverage?**
> `next_state` is combinational and can glitch. A glitch could falsely
> trigger coverage before the clock edge confirms the transition.
> `prev_state` only fires after the flop has committed — reflecting
> what the hardware actually did.

---

## Testbench 1 — Manual Coverage Tracking

**Purpose:** Manually track which states and transitions are visited using variables/flags.

```systemverilog
// Track state visits
bit visited_A, visited_B, visited_C, visited_D, visited_E;

// Track transitions
bit trans_A_to_B, trans_B_to_C, trans_C_to_D;

// prev_state used here — not next_state (see note above)
reg [2:0] prev_state;

always @(posedge clk) begin
    // State coverage
    case (state)
        STATE_A: visited_A = 1;
        STATE_B: visited_B = 1;
        STATE_C: visited_C = 1;
        STATE_D: visited_D = 1;
        STATE_E: visited_E = 1;
    endcase

    // Transition coverage — prev_state lags by one cycle,
    // confirming the transition actually committed through the flop
    if (prev_state == STATE_A && state == STATE_B) trans_A_to_B = 1;
    if (prev_state == STATE_B && state == STATE_C) trans_B_to_C = 1;
    if (prev_state == STATE_C && state == STATE_D) trans_C_to_D = 1;

    prev_state <= state;
end

// Final coverage report
final begin
    $display("=== Manual Coverage Report ===");
    $display("State A visited:    %0b", visited_A);
    $display("State B visited:    %0b", visited_B);
    $display("State C visited:    %0b", visited_C);
    $display("A->B transition:    %0b", trans_A_to_B);
    $display("B->C transition:    %0b", trans_B_to_C);
    $display("C->D transition:    %0b", trans_C_to_D);
end
```

---

## Testbench 2 — Automatic Coverage with Covergroups

**Purpose:** Use SystemVerilog covergroups to automatically collect coverage data during simulation.
The covergroup samples `state` at each clock edge — the `=>` transition operator internally
tracks the previous value, equivalent to what `prev_state` does manually in TB1.

```systemverilog
covergroup fsm_cg @(posedge clk);

    // State coverage
    cp_state: coverpoint state {
        bins state_a = {STATE_A};
        bins state_b = {STATE_B};
        bins state_c = {STATE_C};
        bins state_d = {STATE_D};
        bins state_e = {STATE_E};
    }

    // Transition coverage
    // The => operator automatically tracks consecutive sampled values
    // (equivalent to prev_state -> state in TB1)
    cp_trans: coverpoint state {
        bins a_to_b = (STATE_A => STATE_B);
        bins b_to_c = (STATE_B => STATE_C);
        bins c_to_d = (STATE_C => STATE_D);
        bins c_to_e = (STATE_C => STATE_E);
        bins d_to_a = (STATE_D => STATE_A);
        bins e_to_e = (STATE_E => STATE_E);
    }

endgroup

// Instantiate and sample
fsm_cg cg_inst = new();

// Query coverage at end of sim
final begin
    $display("Functional Coverage: %.2f%%", cg_inst.get_coverage());
end
```

---

## SystemVerilog Assertions (SVA)

**Purpose:** Define formal properties that must always hold true. Used for protocol checking and design correctness.

```systemverilog
property rule_example;
    @(posedge clk)
    (state == SOME_STATE) |-> expected_condition;
endproperty

assert property(rule_example);
```

---

## UVM (Universal Verification Methodology)

**Purpose:** Industry-standard SystemVerilog verification framework.

| Component    | Role                          |
|--------------|-------------------------------|
| `driver`     | Sends stimulus to DUT         |
| `monitor`    | Observes DUT signals          |
| `scoreboard` | Checks correctness of outputs |
| `agent`      | Groups driver + monitor       |

> **Note:** UVM is significantly more advanced than basic HDL testbenches
> and is commonly used in large-scale industrial verification.

