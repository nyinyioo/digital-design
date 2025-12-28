module top_module (
    input clk,
    input reset,
    output OneHertz,
    output [2:0] c_enable
); //


/*

Count 1000 clock cycles, then produce a pulse, assert oneHertz


BCD Counter: mod-10 
------------------------------
Total states 0–9 → wrap to 0


Cartesian Product: 
---------------------
given sets A and B, AxB = {(a,b) | a in A, b in B}
if A and B are finite, |AxB| = |A| * |B|
each BCD counter => S = {0,1,2,3,4,5,6,7,8,9}, cardinality = |S| = 10
cascade S0, S1, S2, |S2*S1*S0| = 10*10*10 = 1000
equivalent to (mod 1000), wraps around


*/
    wire [3:0] q0, q1, q2;

    //control logic
    assign c_enable[0] = 1'b1;           
    assign c_enable[1] = (q0 == 4'd9);   
    assign c_enable[2] = (q0 == 4'd9) & (q1 == 4'd9);

    // Three cascaded BCD counters, all driven by the same clk
    bcdcount c0 (clk, reset, c_enable[0], q0);
    bcdcount c0 (clk, reset, c_enable[1], q1);
    bcdcount c0 (clk, reset, c_enable[2], q2);
   
    // One-cycle pulse every 1000 cycles (when count == 999)
    assign OneHertz = (q0 == 4'd9) & (q1 == 4'd9) & (q2 == 4'd9);

endmodule
