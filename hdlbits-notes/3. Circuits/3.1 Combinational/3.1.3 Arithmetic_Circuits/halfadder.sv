module top_module( 
    input a, b,
    output cout, sum );

       /*
    00 -> c=0,s=0
    01 -> c=0,s=1
    10 -> c=0,s=1 
    11 -> c=1,s=0
    */
    
    assign sum = a^b;
    assign cout = (a & b);
    
endmodule