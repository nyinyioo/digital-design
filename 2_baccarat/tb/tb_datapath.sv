`timescale 1ns/1ps

module tb_datapath();
	
	// Integration testbench for datapath 
	// declare signals
	logic slow_clock, fast_clock, resetb;
	logic load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3;
	logic [3:0]  pcard3_out, pscore_out, dscore_out;
	logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	  
	//declare intermediate signals
	wire [3:0] pcard1;
	wire [3:0] pcard2;
	wire [3:0] pcard3;
	wire [3:0] dcard1;
	wire [3:0] dcard2;
	wire [3:0] dcard3;

	assign pcard1 = UUT.pcard1;
	assign pcard2 = UUT.pcard2;
	assign pcard3 = UUT.pcard3;
	assign dcard1 = UUT.dcard1;
	assign dcard2 = UUT.dcard2;
	assign dcard3 = UUT.dcard3;

	// instantiate UUT
	datapath UUT (.slow_clock(slow_clock), .fast_clock(fast_clock), .resetb(resetb),
				.load_pcard1(load_pcard1), .load_pcard2(load_pcard2), .load_pcard3(load_pcard3),
				.load_dcard1(load_dcard1), .load_dcard2(load_dcard2), .load_dcard3(load_dcard3),
				.pcard3_out(pcard3_out),
				.pscore_out(pscore_out), .dscore_out(dscore_out), 
				.HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3),
				.HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0));


	// fast clock (50MHz)
	initial fast_clock = 1'b0;
	always #10 fast_clock = ~fast_clock; // 10ns, period = 20ns = 50MHz

	// slow clock derived from fast_clock (divide by 2 = 25MHz) but note that on the real board
	// the KEY0 is gonna be asynchronous to the fast_clock. So here for testing they're going to be synchronous
	// if we wanted to model asynchronous KEY0 behavior, we'd just generate slow_clock with its own #delay independed of fast_clock
	initial slow_clock = 1'b0;
	always @(posedge fast_clock) begin
		slow_clock <= ~slow_clock;
	end

	// Signals for computing the baccarat scores 
	logic [5:0] psum, dsum; 
	logic [3:0] pv1, pv2, pv3, dv1, dv2, dv3;
	logic [3:0] pexp, dexp; 

	// Need to be able to store previous card values so we can check hold works properly 
	logic [3:0] p1_prev, p2_prev, p3_prev, d1_prev, d2_prev, d3_prev; 
	
	//testbench
	initial begin
	
		// initialize singals 
		load_pcard1 = 1'b0;
		load_pcard2 = 1'b0;
		load_pcard3 = 1'b0;
		load_dcard1 = 1'b0;
		load_dcard2 = 1'b0;
		load_dcard3 = 1'b0;

		$display ("Game 1 Begins .....................................................................");
		
		// Reset test we will have reset activated for multiple edges so the registers clear 
		resetb = 1'b0;
		@(posedge slow_clock);
		@(posedge slow_clock);
		@(posedge slow_clock);

		// Now make sure there are no cards (all should be 0 = blank)
		assert(pcard1 == 4'd0 && pcard2 == 4'd0 && pcard3 == 4'd0 && dcard1 == 4'd0 && dcard2 == 4'd0 && dcard3 == 4'd0)
            else $fatal(1, "Reset failed: expected all card regs = 0");

		 // Deassert reset
		resetb = 1'b1; 
		@(posedge slow_clock);
		#1; 

		// Hold test : we will make sure none of the card values change when loads are off 
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

		@(posedge slow_clock); 
		#1;

        assert(pcard1 == p1_prev && pcard2 == p2_prev && pcard3 == p3_prev && dcard1 == d1_prev && dcard2 == d2_prev && dcard3 == d3_prev)
            else $fatal(1, "Hold failed: registers changed when all loads were 0");


		// Load tests: For each card we will save the previous reg and assert load and make sure 
		// 			   the card gets updated on posedge and all other registers should stay the same 

		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

		// load pcard1 
		@(negedge slow_clock);
        load_pcard1 = 1'b1;
        @(posedge slow_clock); #1;
        load_pcard1 = 1'b0;

        assert(pcard1 >= 4'd1 && pcard1 <= 4'd13)
            else $fatal(1, "pcard1 load failed: got %0d", pcard1);

		// none of the other cards should've changed 
        assert(pcard2 == p2_prev && pcard3 == p3_prev && dcard1 == d1_prev && dcard2 == d2_prev && dcard3 == d3_prev)
            else $fatal(1, "Isolation failed on load_pcard1");

		// load_dcard1
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

        @(negedge slow_clock);
        load_dcard1 = 1'b1;
        @(posedge slow_clock); #1;
        load_dcard1 = 1'b0;

        assert(dcard1 >= 4'd1 && dcard1 <= 4'd13)
            else $fatal(1, "dcard1 load failed: got %0d", dcard1);

        assert(pcard1 == p1_prev && pcard2 == p2_prev && pcard3 == p3_prev && dcard2 == d2_prev && dcard3 == d3_prev)
            else $fatal(1, "Isolation failed on load_dcard1");
		
		
		// load_pcard2
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

		@(negedge slow_clock);
        load_pcard2 = 1'b1;
        @(posedge slow_clock); #1;
        load_pcard2 = 1'b0;

        assert(pcard2 >= 4'd1 && pcard2 <= 4'd13)
            else $fatal(1, "pcard2 load failed: got %0d", pcard2);

        assert(pcard1 == p1_prev && pcard3 == p3_prev && dcard1 == d1_prev && dcard2 == d2_prev && dcard3 == d3_prev)
            else $fatal(1, "Isolation failed on load_pcard2");


		// load_dcard2
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

	    @(negedge slow_clock);
        load_dcard2 = 1'b1;
        @(posedge slow_clock); #1;
        load_dcard2 = 1'b0;

        assert(dcard2 >= 4'd1 && dcard2 <= 4'd13)
            else $fatal(1, "dcard2 load failed: got %0d", dcard2);

        assert(pcard1 == p1_prev && pcard2 == p2_prev && pcard3 == p3_prev && dcard1 == d1_prev && dcard3 == d3_prev)
            else $fatal(1, "Isolation failed on load_dcard2");

		// load_pcard3
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

		
		@(negedge slow_clock);
        load_pcard3 = 1'b1;
        @(posedge slow_clock); #1;
        load_pcard3 = 1'b0;

        assert(pcard3 >= 4'd1 && pcard3 <= 4'd13)
            else $fatal(1, "pcard3 load failed: got %0d", pcard3);

        assert(pcard1 == p1_prev && pcard2 == p2_prev && dcard1 == d1_prev && dcard2 == d2_prev && dcard3 == d3_prev)
            else $fatal(1, "Isolation failed on load_pcard3");

		// load_dcard3
		p1_prev = pcard1; 
		p2_prev = pcard2; 
		p3_prev = pcard3;
        d1_prev = dcard1; 
		d2_prev = dcard2; 
		d3_prev = dcard3;

	    @(negedge slow_clock);
        load_dcard3 = 1'b1;
        @(posedge slow_clock); #1;
        load_dcard3 = 1'b0;

        assert(dcard3 >= 4'd1 && dcard3 <= 4'd13)
            else $fatal(1, "dcard3 load failed: got %0d", dcard3);

        assert(pcard1 == p1_prev && pcard2 == p2_prev && pcard3 == p3_prev && dcard1 == d1_prev && dcard2 == d2_prev)
            else $fatal(1, "Isolation failed on load_dcard3");

		
		// Now make sure the scores are propery working with both the player and dealer 
		// Player values (convert the card values to baccarat value first)
        if (pcard1 >= 4'd1 && pcard1 <= 4'd9) pv1 = pcard1; else pv1 = 4'd0;
        if (pcard2 >= 4'd1 && pcard2 <= 4'd9) pv2 = pcard2; else pv2 = 4'd0;
        if (pcard3 >= 4'd1 && pcard3 <= 4'd9) pv3 = pcard3; else pv3 = 4'd0;

		// Compute the sum then score : score = (pv1+pv2+pv3) mod 10
		psum = {2'b0,pv1} + {2'b0,pv2} + {2'b0,pv3};

		// similar calcs as scorehand 
		if (psum >= 6'd20) pexp = psum - 6'd20;
        else if (psum >= 6'd10) pexp = psum - 6'd10;
        else pexp = psum[3:0];

		// now make sure the datapaths score matches the expected score (this should be right if scorehand is also wokring)
        assert(pscore_out == pexp)
            else $fatal(1, "pscore mismatch: expected %0d, got %0d", pexp, pscore_out);

        // Dealer values (same process)
        if (dcard1 >= 4'd1 && dcard1 <= 4'd9) dv1 = dcard1; else dv1 = 4'd0;
        if (dcard2 >= 4'd1 && dcard2 <= 4'd9) dv2 = dcard2; else dv2 = 4'd0;
        if (dcard3 >= 4'd1 && dcard3 <= 4'd9) dv3 = dcard3; else dv3 = 4'd0;

        dsum = {2'b0,dv1} + {2'b0,dv2} + {2'b0,dv3};

        if(dsum >= 6'd20) dexp = dsum - 6'd20;
        else if (dsum >= 6'd10) dexp = dsum - 6'd10;
        else dexp = dsum[3:0];

        assert(dscore_out == dexp)
            else $fatal(1, "dscore mismatch: expected %0d, got %0d", dexp, dscore_out);


		// Test reset again 
		@(posedge slow_clock);
		resetb = 1'b0;  // Assert reset (active low)
		@(posedge slow_clock);
		@(posedge slow_clock);

		assert(pcard1 == 4'd0 && pcard2 == 4'd0 && pcard3 == 4'd0 && dcard1 == 4'd0 && dcard2 == 4'd0 && dcard3 == 4'd0)
            else $fatal(1, "Second reset failed: regs not cleared");

        $display("All datapath integration checks passed!");
        $finish;
	end
endmodule