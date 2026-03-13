module top_module (
    input c,
    input d,
    output [3:0] mux_in
); 

/*

KMAP
-------------------------------
           ab
          00  01  11  10
cd  00     0   0   0   1
    01     1   0   0   0
    11     1   0   1   0
    10     1   0   0   1

top_module 4:1 MUX with select (ab)
----------------------------------
        c,d                        (a,b)
         |                           |
         v                           |
   +--------------+                  v
   |  top_module  |                  _
   |              |                 |  \
   |              | mux_in[0] ----->|   \
   |              | mux_in[1] ----->| 00 |
   |              | mux_in[2] ----->| 01 | 
   |              | mux_in[3] ----->| 10 |
   +--------------+                 | 11 |
                                    |   /
                                    |_ /
                   
                   
    
min SOP f = (~c & ~d) | (a & ~b & ~d) | (a & b & c & d);

ab	Output =
00	mux_in[0] = c | d; 
01	mux_in[1] = 1'b0
10	mux_in[2] = ~d;
11	mux_in[3] = = c & d;

assign f = (ab == 2'b00) ? mux_in[0] :
           (ab == 2'b01) ? mux_in[1] :
           (ab == 2'b10) ? mux_in[2] :
                           mux_in[3];


Shannon Expansion: 
----------------------------------------
for any any Boolean function 𝑓(𝑥,𝑦,𝑧,…), there exists f = x' (f|x=0) + x (f|x=1)


A 4:1 MUX implements:
f = a'b' f(0,0,c,d) + a'b  f(0,1,c,d) + ab' f(1,0,c,d) + ab  f(1,1,c,d) 
------------------------
| Shannon      | MUX   |
| ------------ | ----- |
| (f(0,0,c,d)) | (D_0) |
| (f(0,1,c,d)) | (D_1) |
| (f(1,0,c,d)) | (D_2) |
| (f(1,1,c,d)) | (D_3) |

A MUX is a hardware implementation of Shannon expansion

*/

assign mux_in[0] = c & ~d; 
assign mux_in[1] = ~c & ~d;    
assign mux_in[2] = ~d;
assign mux_in[3] = (~c & ~d) | (c & d);

endmodule