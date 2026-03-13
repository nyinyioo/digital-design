module top_module (
    input a,
    input b,
    input c,
    input d,
    output out_sop,
    output out_pos
); 
/*
TRUTH TABLE
----------------------
Dec	a	b	c	d	out
0	0	0	0	0	0
1	0	0	0	1	0
2	0	0	1	0	1
3	0	0	1	1	X
4	0	1	0	0	0
5	0	1	0	1	0
6	0	1	1	0	0
7	0	1	1	1	1
8	1	0	0	0	X
9	1	0	0	1	0
10	1	0	1	0	0
11	1	0	1	1	X
12	1	1	0	0	X
13	1	1	0	1	0
14	1	1	1	0	0
15	1	1	1	1   1


KMAP
----------------------
            cd
          00  01  11  10
        ------------------
ab  00 |   0   0   X   1
    01 |   0   0   1   0
    11 |   X   0   1   0
    10 |   X   0   X   0


DEMORGAN'S THEOREM
(A + B)' = A'B'
(A B)' = A' + B'

DISTRIBUTIVE LAW
A B + A C = A (B + C)
A + B C = (A + B)(A + C)

*/

assign out_sop = (c & d) | (~a & ~b & c);
assign out_pos = c & (d | ~a) & (d | ~b);

endmodule
