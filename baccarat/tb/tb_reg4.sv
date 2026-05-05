module tb_reg4();

// testbench for reg4 

// parameters 
logic rst_n, clk, load;
logic [3:0] card_in, card_out; 


// Insantiate reg4
reg4 UUT(.clk(clk), .rst_n(rst_n), .load(load), .card_in(card_in), .card_out(card_out));

// clock generator
initial begin 
	clk = 1'b0;
	forever #5 clk = ~clk; 
end 


initial begin 
	
	// set our initial conditions (reset off (1), load to zero and card in to 0)
	rst_n = 1'b1; 
	load = 1'b0;
	card_in = 4'h0;
	
	// Test 1: Verify synchronous reset 
	rst_n = 1'b0; // reseet is active low so 0 means assert reset
	card_in = 4'hA;
	load = 1'b1; 
	
	// wait for rising edge 
	@(posedge clk);
	#1;
	assert (card_out == 4'b0000)
		else $fatal(1, "Reset failed: expected 0000, got %b", card_out);
		
	// turn reset off 
	rst_n = 1'b1;
	load = 1'b0; 
	card_in = 4'h0; 
	
	
	// Test 2: Make sure load works properly (card out changes when load is set) 
	card_in = 4'h5;
	load = 1'b1; 
	@(posedge clk); 
	#1; 
	assert (card_out == 4'h5)
		else $fatal(1, "Load failed: expected 5, got %h", card_out); 
		
	
	// Now make sure that when load is set to 0 card_out doesn't change and keeps the old value 
	load = 1'b0; 
	card_in = 4'h9;
	@(posedge clk); 
	#1; 
	assert (card_out == 4'h5)
		else $fatal(1, "Load failed (did not keep old value): expected 5, got %h", card_out); 
		
	
	// Test 3: set load to 1 and then activate reset make sure the card output is 0 
	
	rst_n = 1'b0;
   load = 1'b1;
   card_in = 4'hF;
   @(posedge clk);
   #1;
   assert (card_out == 4'b0000)
      else $fatal(1, "Reset priority failed: expected 0000, got %b", card_out);
	
	$display("All reg4 tests passed!"); 
	$finish;
end 


endmodule 
