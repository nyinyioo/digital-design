module top_module( 
    input a, b, cin,
    output cout, sum );
   /*
    000 -> c=0,s=0
    001 -> c=0,s=1
    010 -> c=0,s=1 
    011 -> c=1,s=0
    100 -> c=0,s=1
    101 -> c=1,s=0 
    110 -> c=1,s=0
    111 -> c=1,s=1
    */
    
    assign sum = a^b^cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule