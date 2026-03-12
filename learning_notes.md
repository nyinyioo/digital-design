# SystemVerilog Best Practices

## Table of Contents
1. [State Encoding: enum vs parameter](#1-state-encoding-enum-vs-parameter)
2. [Static vs Automatic Tasks](#2-static-vs-automatic-tasks)
3. [Unique and Priority Case Statements](#3-unique-and-priority-case-statements)

---

## 1. State Encoding: enum vs parameter

### Old way (Verilog)
```systemverilog
parameter CLR = 2'd0, WAIT = 2'd1, PLOT = 2'd2, DONE = 2'd3;
reg [1:0] state, next_state;
```

### New way (SystemVerilog)
```systemverilog
typedef enum logic [1:0] {
    CLR  = 2'd0,
    WAIT = 2'd1,
    PLOT = 2'd2,
    DONE = 2'd3
} state_t;

state_t state, next_state;
```

### Why enum wins

|                 | parameter + reg        | typedef enum             |
| --------------- | ---------------------- | ------------------------ |
| type safety     | ❌ any value assignable | ✅ only valid states      |
| tool support    | ❌ none                 | ✅ Quartus auto-detects   |
| waveform viewer | shows 0,1,2,3          | shows CLR,WAIT,PLOT,DONE |
| invalid state   | silent bug             | simulation warning       |
| verible         | warns missing type     | clean                    |

### In waveform viewer
```
parameter:   state = 2
enum:        state = PLOT    ← way easier to debug
```

### Synthesis benefit
```
unique case + enum → Quartus infers parallel mux
parameter + case   → Quartus may infer priority encoder
```

### One line summary
```
reg + parameter  →  Verilog style, avoid in new code
logic + enum     →  SystemVerilog best practice
```

---

## 2. Static vs Automatic Tasks

|            | static                | automatic       |
| ---------- | --------------------- | --------------- |
| variables  | persist between calls | fresh each call |
| default in | modules               | classes         |
| use for    | RTL tasks             | testbench tasks |

### RTL (module) — static is fine
```systemverilog
task counter;
    // writing to module-level signals
    // static vs automatic doesn't matter
    x_count <= x_count + 1;
endtask
```

### Testbench — use automatic
```systemverilog
// automatic — safe ✅
task automatic send_bit(input logic b);
    logic [1:0] cur_state;  // fresh each call
    logic [1:0] cur_next;   // no leftover values
    ...
endtask

// static — dangerous ❌
task static send_bit;
    logic [1:0] cur_state;  // persists between calls
    logic [1:0] cur_next;   // stale values from last call
endtask
```

### One line summary
```
RTL tasks  → static    (default, don't need to write it)
TB tasks   → automatic (always write it explicitly)
```

---

## 3. Unique and Priority Case Statements

|                 | case         | unique case  | priority case    |
| --------------- | ------------ | ------------ | ---------------- |
| checks overlap  | ❌            | ✅ warns      | ❌                |
| checks coverage | ❌            | ✅ warns      | ❌                |
| synthesis       | priority enc | parallel mux | priority encoder |
| use for         | Verilog only | FSM states   | arbiters         |
```systemverilog
// Verilog — no checks
case(state)

// SystemVerilog — parallel, warns on overlap or missing branch
unique case(state)
    CLR:  vga_colour = 3'b000;
    WAIT: vga_plot   = 1'b0;
    PLOT: vga_colour = x_count[2:0];
    DONE: done       = 1'b1;
endcase

// SystemVerilog — first match wins (like if-else chain)
priority case(1'b1)
    r[1]: next_state = G1;  // highest priority
    r[2]: next_state = G2;
    r[3]: next_state = G3;
endcase
```

### When to use what
```
FSM next state logic  → unique case
FSM output logic      → unique case
Arbiter priority      → priority case
Verilog compatibility → plain case
```

### Always add defaults before unique case
```systemverilog
always_comb begin
    // defaults first — prevents latches
    vga_plot   = 1'b0;
    vga_colour = 3'b000;
    done       = 1'b0;

    unique case(state)  // then override per state
        ...
    endcase
end
```