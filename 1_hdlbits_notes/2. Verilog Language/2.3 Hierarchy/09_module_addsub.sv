module top_module(
    input [31:0] a,
    input [31:0] b,
    input sub,
    output [31:0] sum
);  

    //assign internal signals
  	wire cout;
    wire [31:0] bsub;

    //instantiate modules
    add16 mod1( .a(a[15:0]), .b(bsub[15:0]), .cin(sub), .sum(sum[15:0]), .cout(cout));
    add16 mod2( .a(a[31:16]), .b(bsub[31:16]), .cin(cout), .sum(sum[31:16]), .cout(0));

    //assign outputs
    assign bsub = (b ^ {{32{sub}}});

endmodule