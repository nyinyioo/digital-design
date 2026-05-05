## Baccarat
Implements a game of Baccarat on a DE1-SoC FPGA board using SystemVerilog and Quartus.

### Components
- **dealcard**:  50MHz counter to deal random cards [Ace=1, King=13]
- **card7seg** : Combinational 4-bit card value to seven-segment display decoder
- **scorehand**: Computes player and dealer scores as (Value1 + Value2 + Value3) mod 10 
- **datapath**:  Wires six reg4, two scorehand, and six card7seg blocks to track and score each hand
- **statemachine**:  Controls card dealing (load_pcard1–3, load_dcard1–3)  
  based on player/dealer scores and Baccarat drawing rules; determines winner

<!-- ### Demos
<p>
  <img src="docs/demo_imgs/baccarat1.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/baccarat2.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/baccarat3.jpeg" width="28.25"/>
</p> -->

### FSM Structure
All modules use a 3-block Moore FSM:
- Input Combinational Logic, Sequential State Register, Output Combinational Logic.
- Helper tasks and counters handle card dealing logic.

### Testbenches
RTL testbenches for `scorehand`, `datapath`, and `statemachine`. 


### Note
Completed in a team of two. Shared with permissions.