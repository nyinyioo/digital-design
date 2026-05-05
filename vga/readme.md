## VGA
Draws graphics on a 160x120 VGA display using a DE1-SoC and Quartus.

### Demos
<p>
  <img src="docs/demo_imgs/fillscreen.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/circle.jpeg" width="28.25%"/>
  <img src="docs/demo_imgs/reuleaux.jpeg" width="30%"/>
</p>

### FSM Structure
All modules use a 3-block Moore FSM: 
- Input Combinational Logic, Sequential State Register, Output Combinational Logic. 
- Helper tasks and counters handle drawing logic.

### Testbenches
Manual coverage testbenches track state/transition coverage and cycle counts.

### Note
Completed in a team of two. Shared with permissions.