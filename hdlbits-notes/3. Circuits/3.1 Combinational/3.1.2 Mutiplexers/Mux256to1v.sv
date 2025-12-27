module top_module( 
    input [1023:0] in,
    input [7:0] sel,
    output [3:0] out );

    /*
    note: assign out = in [(sel*4)+3:sel*4];

    part ranges must be constant at complie time, 
    so we cannot use variable sel directly.
    
    we use part select:  [start_index +: width]
    */

    assign out = in[sel*4 +: 4];

endmodule