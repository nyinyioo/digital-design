module top_module(
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);

    //assign internal signals
    wire [15:0] upper, lower;
    wire cout1;

    //instantiate 2 full adders
    add16 mod1(.a(a[15:0]),.b(b[15:0]),.cin(0),.sum(lower),.cout(cout1));
    add16 mod2(.a(a[31:16]),.b(b[31:16]),.cin(cout1),.sum(upper), .cout(0)); 

    //assign output
    assign sum = {upper, lower};
    

endmodule
