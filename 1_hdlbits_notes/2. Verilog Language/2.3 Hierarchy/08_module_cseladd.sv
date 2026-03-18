module top_module(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);

    //assign internal signals
    wire cout1;
    wire [15:0] upper1, upper2;

    //instantiate modules
    add16 mod1( .a(a[15:0]), .b(b[15:0]), .cin(0), .sum(sum[15:0]), .cout(cout1));
    add16 mod2( .a(a[31:16]), .b(b[31:16]), .cin(0), .sum(upper1), .cout(0));
    add16 mod3( .a(a[31:16]), .b(b[31:16]), .cin(1), .sum(upper2), .cout(0));

    //assign outputs
    assign sum[31:16] = cout1 ? upper2: upper1;
endmodule
