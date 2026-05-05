module tb_dealcard();
	
	logic clock, resetb;
	logic [3:0] new_card;
	
	dealcard UUT(.clock(clock), .resetb(resetb), .new_card(new_card));
	
	initial begin 
		clock = 1'b0;
		forever #5 clock = ~clock; 
	end 
	
	initial begin 
		
		resetb = 1'b1;
		
		// Test 1: make sure the new card is set to 1 when we assert reset 
		resetb = 1'b0;
		@(posedge clock); 
		#1;
		assert (new_card == 4'd1)
			else $fatal(1, "Reset failed: expected 1, got %0d", new_card);
			
		resetb = 1'b1;
		
		// Test 2: now if previous test passed we know deal card is 1 so now make sure it loops
		//			  through the numbers correctly and that it wraps around right 
		for (int expected_card = 2; expected_card <= 13; expected_card++) begin 
			@(posedge clock); 
			#1; 
			assert (new_card == expected_card[3:0])
				else $fatal(1, "Deal card not properly counting cards: expected %0d, got %0d", expected_card, new_card);
		end 
		
		// Now check wrap around 
		@(posedge clock);
		#1; 
		assert (new_card == 4'd1)
			else $fatal(1, "wrap around failed, expected 1 got %0d", new_card); 
			
		$display("all dealcard tests passed");
		$finish;
	end 
endmodule 
		
		
