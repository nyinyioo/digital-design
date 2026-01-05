
`timescale 1ns/1ps
module tb_top_module();
	
	//declare signals
    logic clk, areset, bump_left, bump_right, ground, dig;
    logic walk_left, walk_right, aaah, digging;
    logic [2:0] state, next_state;
    logic [4:0] fall_count_left, fall_count_right;
    integer i, j;


    //instantiate UUT
	top_module UUT(
	    clk,
	    areset,   
	    bump_left,
	    bump_right,
	    ground,
	    dig,
	    walk_left,
	    walk_right,
	    aaah,
	    digging); 

    //clock generation
    initial clk = 1'b0;
	always #10 clk = ~clk;

    //testbench
    initial begin

    //initialize signals
	 	areset = 1'b0;
	    bump_left = 1'b0;
	    bump_right = 1'b0;
	    ground = 1'b1;
	    dig = 1'b0;

    	#10;

    	//state: WL -> reset logic
    	areset = 1'b1; #10;
    	areset = 1'b0; #10;


    	$display("////////////////TEST CASES//////////////////////////////");

		

    	$display("WL(0) -> WR(1) ------------------------------------------");
		/*
         	             ----------
    	state: WL(0) ->| bump_left |  -> state: WR(1)
    	       	         ----------
		*/

    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

    	bump_left = 1'b1; #10;
    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

		bump_left = 1'b0; #10;
    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);


    	$display("WR(1) -> WL(0) ------------------------------------------");
		/*
         	             ----------
    	state: WR(1) ->| bump_right |  -> state: WL (0)
    	       	          ----------
		*/	

    	$display("BUMP RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);	

    	bump_right = 1'b1; #10;
    	$display("BUMP RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

		bump_right = 1'b0; #10;
		$display("BUMP RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);




		$display("WL(0) -> DL(4) ------------------------------------------");
		/* 
         	             ----------
    	state: WL(0) ->|   dig    |  -> state: DL(4)
    	       	         ----------
		*/		

    	$display("DIG LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);	

    	dig = 1'b1; #10;
    	$display("DIG LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

    	dig = 1'b0; #10;
    	$display("DIG LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);



    	$display("DL(4) -> FL(2) -----------------------------------------");
	    /*
         	             ----------
    	state: DL(4) ->| ground<=20 |  -> state: FL(2) ->    state: WL(0)
    	       	         ----------
		*/	

		$display("FALL LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
	
   		ground = 1'b0; #10;
    	$display("FALL LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);


    		$display("fall count starting .............");
	    	/*
	    	FALL COUNTER LOGIC case: <20 clock cycle -> causes no splatter
	    	need some logic to display some logic at like 0-10
	    	*/

	    
	        //fall count
	        repeat (10) begin  // covers 0..255 + a few cycles to see DONE
	            @(posedge clk);
	            $display("fall count left :%0d", UUT.top_module.fall_count_left);
	        end


		$display("FL(2) -> WL(0)--------------------------------------");
    	ground = 1'b1; #20;
    	$display("WALK LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);



    	$display("WL(0) -> WR(1)--------------------------------------");
		/*
         	            ----------
    	state: WL(0) ->| bump_left |  -> state: WR(1)
    	       	        ----------
		*/	

    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

    	bump_left = 1'b1; #10;
    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
    	#10;

		bump_left = 1'b0; #10;
    	$display("BUMP LEFET: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);




    	$display("WR(1) -> DR(5)--------------------------------------");
		/*
         	            ----------
    	state: WR(1) ->|    dig   |  -> state: DR (5)
    	       	        ----------
		*/		

    	$display("DIG RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);	

    	dig = 1'b1; #10;
    	$display("DIG RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);

    	dig = 1'b0; #10;
    	$display("DIG RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);




		$display("DR(5) -> FR(3)--------------------------------------");
		/*
         	             ----------
    	state: DR(5) ->| ground>20  |  -> state: FR(3)-> state: SPLAT(6)
    	       	         ----------
		*/		    	

		$display("FALL RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
	
   		ground = 1'b0; #30;
    	$display("FALL RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);


    		$display("fall count starting .............");
	    	/*
	    	FALL COUNTER LOGIC case: 21 clock cycle -> causes a splatter
	    	*/

	   

	        repeat (25) begin  // covers 0..255 + a few cycles to see DONE
	            @(posedge clk);
	            $display("fall count left :%0d", UUT.top_module.fall_count_left);
	            $display("fall count right :%0d", UUT.top_module.fall_count_right);
	        end



	    $display("FR(3) -> SPLAT(6)--------------------------------------");
    	ground = 1'b1; #30; //need 30 to stabilize to splatter.
    	$display("SPLATTER: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
	    

    	$display("SPLAT(6) --> X --------------------------------------");
    

    	bump_left = 1'b1; #10;
    	$display("SPLATTER BUMP LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
		bump_left = 1'b0; #10;

    	dig = 1'b1; #10;
    	$display("SPLATTER DIG RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
    	dig = 1'b0; #10;

    	bump_right = 1'b1; #10;
    	$display("SPLATTER BUMP RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
		bump_right = 1'b0; #10;

    	dig = 1'b1; #10;
    	$display("SPLATTER DIG LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
    	dig = 1'b0; #10;
   
   		ground = 1'b0; #25;
    	$display("SPLATTER FALL LEFT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
		ground = 1'b1; #10;

   
   		ground = 1'b0; #25;
    	$display("SPLATTER FALL RIGHT: state:%0d and nextstate: %0d", UUT.top_module.state, UUT.top_module.next_state);
		ground = 1'b1; #10;


    	$stop();

    end
endmodule








