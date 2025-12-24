module top_module (
    input [7:0] in,
    output parity); 

/* 
The reduction operators can do AND, OR, and XOR of the bits of a vector, producing one bit of output:
& a[3:0]     AND: a[3]&a[2]&a[1]&a[0]. Equivalent to (a[3:0] == 4'hf) 
meaning only when all bits are 1111, will the output be  1111 = 4'hf = 15;
| b[3:0]     OR:  b[3]|b[2]|b[1]|b[0]. Equivalent to (b[3:0] != 4'h0)
is just the negation of all bits being 0000, so if any bit is 1, the output is 1;
^ c[2:0]     XOR: c[2]^c[1]^c[0]
*/

    assign parity = ^in[7:0];

endmodule
