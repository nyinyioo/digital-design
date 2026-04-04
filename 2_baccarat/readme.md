## Baccarat
Implements a game of Baccarat on a DE1-SoC FPGA board using SystemVerilog and Quartus.

### Components
- **dealcard** — 50MHz counter-based random card generator (Ace=1 to King=13)
- **card7seg** — Combinational 4-bit card value to seven-segment display decoder
- **scorehand** — Computes hand score as (Value1 + Value2 + Value3) mod 10
- **datapath** — Holds all six card registers and wires components together
- **statemachine** — Sequences card dealing (load_pcard1–3, load_dcard1–3)  
  based on player/dealer scores and Baccarat drawing rules; determines winner

### Demos
<p>
  <img src="docs/demo_imgs/baccarat1.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/baccarat2.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/baccarat3.jpeg" width="30%"/>
</p>

### FSM Structure
All modules use a 3-block Moore FSM:
- Input Combinational Logic, Sequential State Register, Output Combinational Logic.
- Helper tasks and counters handle card dealing sequencing.

### Testbenches
Manual coverage testbenches track state/transition coverage for `scorehand`, `datapath`, and `statemachine`. 
Both RTL and post-synthesis netlists are tested.

### Note
Completed in a team of two. Shared with permissions.