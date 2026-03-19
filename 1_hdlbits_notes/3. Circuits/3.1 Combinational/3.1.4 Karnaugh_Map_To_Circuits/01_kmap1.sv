module top_module(
    input a,
    input b,
    input c,
    output out  ); 

    /*
        KMap:
        --------------------------------------------------------------------------

            	  a	b out	 Minterm   Maxterm
          0   	0	0	0	   a'b'c'     a+b+c
          1		  0 0	1	   a'b'c      a+b+c'
          2	    0	1	0	   a'b c'     a+b'+c
          3	    0	1	1	   a'b c      a+b'+c'
          4	    1	0	0	   a b'c'     a'+b+c
          5	    1	0	1	   a b'c      a'+b+c'
          6	    1	1	0	   a b c'     a'+b'+c
          7	    1	1	1	   a b c      a'+b'+c'

        minterms: A product (AND) term that is 1 for exactly one input combination
        n variables, there are 2ⁿ minterms
        out = Σm(1,3,5,7)

        maxterms: A sum (OR) term that is 0 for exactly one input combination
        n variables, there are 2ⁿ maxterms
        out = ΠM(0,2,4,6)


        KMAP RULES (POS FORM)
        --------------------------------------------------------------------------
        Make groups as large as possible
        Cover every 1 at least once
        Use the fewest groups
        Groups can overlap if it helps reduce terms
    */
  assign out = a | b | c;


endmodule