module reg4(input logic clk, 
            input logic rst_n, 
            input logic load, 
            input logic [3:0] card_in, 
            output logic [3:0] card_out);

    always @(posedge clk) begin
      //active low reset
      if (!rst_n) begin
        card_out <= 4'b0000; 
      end 
      // load enabled DFF
      else if (load) begin
        card_out <= card_in;
      end
    end
endmodule