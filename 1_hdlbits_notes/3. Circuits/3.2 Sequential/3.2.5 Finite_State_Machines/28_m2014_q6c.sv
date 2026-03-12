module top_module (
    input [6:1] y,
    input w,
    output Y2,
    output Y4
);

/* 
    One-hot encoding:
    ------------------
    A=000001, B=000010, C=000100, D=001000, E=010000, F=100000

    State transitions (from state diagram):
    -----------
    A + w=0 → B
    A + w=1 → A
    B + w=0 → C
    B + w=1 → D
    C + w=0 → E
    C + w=1 → D
    D + w=0 → F
    D + w=1 → A
    E + w=0 → E
    E + w=1 → D
    F + w=0 → C
    F + w=1 → D

    Next state equations: 
    ---------------------
    Y1 (→A): A+w=1, D+w=1 = y[1]&w  | y[4]&w
    Y2 (→B): A+w=0 = y[1]&~w
    Y3 (→C): B+w=0, F+w=0 = y[2]&~w | y[6]&~w
    Y4 (→D): B+w=1, C+w=1, E+w=1, F+w=1 = (y[2]|y[3]|y[5]|y[6])&w
    Y5 (→E): C+w=0, E+w=0 = (y[3]|y[5])&~w
    Y6 (→F): D+w=0 = y[4]&~w

    Yi = sum of all (current_state & input_condition) 
    that transition INTO state i

    Outputs:
    ---------
    z = E | F = y[5] | y[6]
*/

    assign Y2 = y[1] & ~w;
    assign Y4 = (y[2] | y[3] | y[5] | y[6]) & w;

endmodule
