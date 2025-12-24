module top_module( 
    input [99:0] a, b,
    input cin,
    output [99:0] cout,
    output [99:0] sum );


/*
    100-bit ripple-carry adder (carry flow)
    ----------------------------------------
    a[3]  b[3]     a[2]  b[2]     a[1]  b[1]     a[0]  b[0]
      |     |        |     |        |     |        |     |
    +-------+  c2  +-------+  c1  +-------+  c0  +-------+
    |  FA3  |<-----|  FA2  |<-----|  FA1  |<-----|  FA0  | <---- cin
    +-------+      +-------+      +-------+      +-------+
        |              |              |              |
      sum[3]         sum[2]         sum[1]         sum[0]



    Concept (LOOP UNROLLING)
    -------------------------------------
        a.genvar + generate 
            runtime: compile-time
            synthesizable, creates hardware
            useful for instantiating multiple copies of modules or repeating logic
            ex: 100-bit adder, 32-bit multiplier, 16x16 RAM, etc.

            genvar i;
            generate
                for (i = 0; i < 100; i = i + 1) begin
                    assign sum[i] = a[i] ^ b[i];
                end
            endgenerate

            Compiler tool unrolls the loop at compile-time to create 100 separate assignments:
                assign sum[0] = a[0] ^ b[0];
                assign sum[1] = a[1] ^ b[1];
                ...
                assign sum[99] = a[99] ^ b[99];

            There is no loop in hardware.
            The loop disappears before simulation starts.
            genvar controls how many wires/modules exist

        b. integer + always
            runtime: run-time
            not synthesizable, creates sequential logic
            useful for algorithms that require iteration
            ex: state machines, counters, shift registers, etc.

           
            always @(*) begin
                for (i = 0; i < 100; i = i + 1)
                    sum[i] = a[i] ^ b[i];
            end

            Inside always blocks
            Writing combinational logic
            Sequential algorithms
            Counters, shifts, loops over arrays
            
            loop executes during simulation
            It’s a behavioral description
            Hardware still ends up the same if synthesizable


        c. For instantiating 100 full adders:

            genvar 
            FA fa0 (...);
            FA fa1 (...);
            FA fa2 (...);
            ...
            FA fa99 (...);

            You cannot instantiate modules in an always block:
            always @(*) begin
                FA fa;  // not allowed
            end
*/

genvar i;
    generate
        for (i =0; i<100; i= i+1) begin: adders
            if (i== 0) begin
                assign sum[i] = a[i] ^ b[i] ^ cin;
                assign cout[i] =  (a[i] & b[i]) | (a[i] & cin) | (b[i] & cin);
            end else begin
                assign sum[i] = a[i] ^ b[i] ^ cout[i-1];
                assign cout[i] =  (a[i] & b[i]) | (a[i] & cout[i-1]) | (b[i] & cout[i-1]);
            end 
        end
    endgenerate
endmodule
