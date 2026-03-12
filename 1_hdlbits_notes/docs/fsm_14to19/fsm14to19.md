# FSM Problems 14–19

Three protocols, each teaching FSM + datapath co-design progressively.

## Protocol Tracks

**One-hot FSM**
- Derive next-state logic via bitwise ops, no case statement

**PS/2 Track**
- Parser — sync to packet boundary using in[3]==1, discard/resync mechanism
- + datapath — shift bytes in as {out_bytes[15:0], in[7:0]}

**UART Track** ← counter pattern lives here
- Serial receiver — start bit → count 8 bits → stop bit; counter replaces 8 DATA states
- + datapath — LSB-first shift: data <= {in, data[7:1]}
- + parity — submodule instantiation; gate done on stop bit AND odd parity

**HDLC (Sequence Recognition)**
- Detect consecutive 1s; disc on 5, flag on 6, err on 7+
- Counter replaces ONE–SIX states; branch on threshold at count==5/6

## Counter vs. Explicit States

Without counter, unroll into one state per count value:

UART: IDLE → START → D0–D7 → STOP → ERR (12 states)
HDLC: IDLE → ONE–SIX → ERR, DISC, FLAG (10 states) ← reference solution

| | Explicit States | Counter |
|---|---|---|
| State count | High | Low |
| Logic complexity | Simple | Slightly more |
| Scalability | Redraw FSM | Change counter width |
| Readability | Very explicit | More abstract |

Explicit states are easier to draw from a diagram — the HDLBits hint uses this approach.
Counter is better once you recognize the repeating pattern.

**Counter Pattern**

| | UART | HDLC |
|---|---|---|
| Target | Fixed (8) | Variable (5, 6, 7+) |
| Branch on count? | No | Yes |
| Reset on | Start bit | Any 0 or ERR |

UART = **duration** — count up to fixed target (always 8), no branching
HDLC = **classification** — count, then branch on value to determine outcome