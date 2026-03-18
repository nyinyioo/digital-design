module top_module(
    input a,
    input b,
    input c,
    input d,
    output out  ); 

   //initial soln from kmap
    assign out = (~a & b & ~c & ~d) | 
                 (a & ~b & ~c & ~d) | 
                 (~a & ~b & ~c & d) |
                 (~a & ~b & c & ~d) |
                 (a  & b  & c & ~d) |
                 (~a & b & c & d)   |
                 (a  & b &  ~c & d) |
                 (a  & ~b &  c & d);

    //redution by boolean algrebra to get optimal soln
    //parity relation.
    //assign out = ^{a,b,c,d};

endmodule  