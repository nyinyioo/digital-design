module top_module (
    input clk,
    input slowena,
    input reset,
    output [3:0] q);

   reg [3:0] count;
  
  always@(posedge clk) begin
    if (reset) begin
        count <= 4'b0;
    end else if (slowena) begin
        if (count == 9) begin
            count <= 0;
            end else
            count <= count + 1;
        end 
  end 

  assign q = count;

    
endmodule