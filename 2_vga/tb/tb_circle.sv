`timescale 1ns/1ps
module tb_circle();

    // Declare signals
    logic clk, rst_n, start;
    logic [2:0] colour;
    logic [7:0] centre_x;
    logic [6:0] centre_y;
    logic [7:0] radius;
    logic done;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;
    logic vga_plot;

    //state signals
    reg [1:0] state, next_state;

    //intermediate signals
    integer cycle_count;

    // Instantiate DUT
    circle UUT(
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .centre_x(centre_x),
        .centre_y(centre_y),
        .radius(radius),
        .start(start),
        .done(done),
        .vga_x(vga_x),
        .vga_y(vga_y),
        .vga_colour(vga_colour),
        .vga_plot(vga_plot)
    );

    //state variables
    assign state = UUT.state;
    assign next_state = UUT.next_state;
    
    // clock generation: 50MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // testbench
    initial begin
        // initialize
        rst_n    = 1;
        start    = 0;
        colour   = 3'b010; 
        centre_x = 8'd80;
        centre_y = 7'd60;
        radius   = 8'd40;

        // TEST 1: reset
        rst_n = 0;
        @(posedge clk); #1;
        assert(done == 1'b0)       else $error("TEST1 FAIL: done should be 0 on reset, got %0d", done);
        assert(vga_plot == 1'b1)   else $error("TEST1 FAIL: vga_plot should be 1 in CLEAR, got %0d", vga_plot); 
        assert(vga_colour == 3'b0) else $error("TEST1 FAIL: colour should be black in CLEAR, got %0d", vga_colour);
        assert(state == 2'd0)      else $error("TEST1 FAIL: state should be CLEAR, got %0d", state);
        assert(next_state == 2'd0) else $error("TEST1 FAIL: next_state should be CLEAR, got %0d", next_state);
        rst_n = 1;
        @(posedge clk); #1;

        // TEST 2: clear -> wait
        assert(state == 2'd0)      else $error("TEST2 FAIL: should be in CLEAR after reset, got %0d", state);
        assert(next_state == 2'd0) else $error("TEST2 FAIL: next_state should be CLEAR, got %0d", next_state);
        assert(vga_plot == 1'b1)   else $error("TEST2 FAIL: vga_plot should be 1 during CLEAR, got %0d", vga_plot);
        assert(vga_colour == 3'b0) else $error("TEST2 FAIL: colour should be black during CLEAR, got %0d", vga_colour);
        repeat(19200) @(posedge clk); #1;
        assert(state == 2'd1)      else $error("TEST2 FAIL: should be in WAIT after clear, got %0d", state);
        assert(next_state == 2'd1) else $error("TEST2 FAIL: next_state should be WAIT, got %0d", next_state);
        assert(vga_plot == 1'b0)   else $error("TEST2 FAIL: vga_plot should be 0 in WAIT, got %0d", vga_plot);
        //assert(done == 1'b0)       else $error("TEST2 FAIL: done should be 0 in WAIT, got %0d", done);

        // TEST 3: wait -> plot (latch values in WAIT state)
        start = 1;
        @(posedge clk); #1;
        assert(state == 2'd2)          else $error("TEST3 FAIL: should be in PLOT after start, got %0d", state);
        assert(next_state == 2'd2)     else $error("TEST3 FAIL: next_state should be PLOT, got %0d", next_state);
        assert(UUT.offset_x == 8'd40)  else $error("TEST3 FAIL: offset_x should be radius=40, got %0d", UUT.offset_x);
        assert(UUT.offset_y == 7'd0)   else $error("TEST3 FAIL: offset_y should be 0, got %0d", UUT.offset_y);
        assert(UUT.octant == 3'd0)     else $error("TEST3 FAIL: octant should be 0, got %0d", UUT.octant);
        assert(UUT.crit == 9'sd1 - 40) else $error("TEST3 FAIL: crit should be 1-radius=-39, got %0d", UUT.crit);
        assert(vga_plot == 1'b1)       else $error("TEST3 FAIL: vga_plot should be 1 in PLOT, got %0d", vga_plot);

        // TEST 4: first pixel  
        // octant 0: (centre_x + offset_x, centre_y + offset_y) = (80+40, 60+0) = (120, 60)
        assert(vga_plot == 1'b1)    else $error("TEST4 FAIL: vga_plot should be 1, got %0d", vga_plot);
        assert(vga_x == 8'd120)     else $error("TEST4 FAIL: vga_x should be 120, got %0d", vga_x);
        assert(vga_y == 7'd60)      else $error("TEST4 FAIL: vga_y should be 60, got %0d", vga_y);
        assert(vga_colour == 3'b010) else $error("TEST4 FAIL: colour should be green, got %0b", vga_colour);
        assert(UUT.octant == 3'd0)  else $error("TEST4 FAIL: octant should be 0, got %0d", UUT.octant);


        // TEST 5: increment octant
        // advance through octants 1-7, checking each pixel
        // octant 1: (centre_x + offset_y, centre_y + offset_x) = (80+0, 60+40) = (80, 100)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd1)   else $error("TEST5 FAIL: octant should be 1, got %0d", UUT.octant);
        assert(vga_x == 8'd80)       else $error("TEST5 FAIL: oct1 vga_x should be 80, got %0d", vga_x);
        assert(vga_y == 7'd100)      else $error("TEST5 FAIL: oct1 vga_y should be 100, got %0d", vga_y);
        assert(vga_plot == 1'b1)     else $error("TEST5 FAIL: oct1 vga_plot should be 1, got %0d", vga_plot);

        // octant 2: (centre_x - offset_y, centre_y + offset_x) = (80-0, 60+40) = (80, 100)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd2)   else $error("TEST5 FAIL: octant should be 2, got %0d", UUT.octant);
        assert(vga_x == 8'd80)       else $error("TEST5 FAIL: oct2 vga_x should be 80, got %0d", vga_x);
        assert(vga_y == 7'd100)      else $error("TEST5 FAIL: oct2 vga_y should be 100, got %0d", vga_y);

        // octant 3: (centre_x - offset_x, centre_y + offset_y) = (80-40, 60+0) = (40, 60)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd3)   else $error("TEST5 FAIL: octant should be 3, got %0d", UUT.octant);
        assert(vga_x == 8'd40)       else $error("TEST5 FAIL: oct3 vga_x should be 40, got %0d", vga_x);
        assert(vga_y == 7'd60)       else $error("TEST5 FAIL: oct3 vga_y should be 60, got %0d", vga_y);

        // octant 4: (centre_x - offset_x, centre_y - offset_y) = (80-40, 60-0) = (40, 60)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd4)   else $error("TEST5 FAIL: octant should be 4, got %0d", UUT.octant);
        assert(vga_x == 8'd40)       else $error("TEST5 FAIL: oct4 vga_x should be 40, got %0d", vga_x);
        assert(vga_y == 7'd60)       else $error("TEST5 FAIL: oct4 vga_y should be 60, got %0d", vga_y);

        // octant 5: (centre_x - offset_y, centre_y - offset_x) = (80-0, 60-40) = (80, 20)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd5)   else $error("TEST5 FAIL: octant should be 5, got %0d", UUT.octant);
        assert(vga_x == 8'd80)       else $error("TEST5 FAIL: oct5 vga_x should be 80, got %0d", vga_x);
        assert(vga_y == 7'd20)       else $error("TEST5 FAIL: oct5 vga_y should be 20, got %0d", vga_y);

        // octant 6: (centre_x + offset_y, centre_y - offset_x) = (80+0, 60-40) = (80, 20)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd6)   else $error("TEST5 FAIL: octant should be 6, got %0d", UUT.octant);
        assert(vga_x == 8'd80)       else $error("TEST5 FAIL: oct6 vga_x should be 80, got %0d", vga_x);
        assert(vga_y == 7'd20)       else $error("TEST5 FAIL: oct6 vga_y should be 20, got %0d", vga_y);

        // octant 7: (centre_x + offset_x, centre_y - offset_y) = (80+40, 60-0) = (120, 60)
        @(posedge clk); #1;
        assert(UUT.octant == 3'd7)   else $error("TEST5 FAIL: octant should be 7, got %0d", UUT.octant);
        assert(vga_x == 8'd120)      else $error("TEST5 FAIL: oct7 vga_x should be 120, got %0d", vga_x);
        assert(vga_y == 7'd60)       else $error("TEST5 FAIL: oct7 vga_y should be 60, got %0d", vga_y);


        // TEST 6: bresenham updates after octant 7
        // currently on octant 7, offset_x=40, offset_y=0, crit=-39
        // after this cycle: offset_y=1, crit=-39+2*(0+1)+1=-36, offset_x stays 40
        // because crit=-39 <= 0
        @(posedge clk); #1;
        assert(UUT.octant == 3'd0)    else $error("TEST6 FAIL: octant should reset to 0, got %0d", UUT.octant);
        assert(UUT.offset_y == 7'd1)  else $error("TEST6 FAIL: offset_y should be 1, got %0d", UUT.offset_y);
        assert(UUT.offset_x == 8'd40) else $error("TEST6 FAIL: offset_x should still be 40, got %0d", UUT.offset_x);
        assert(UUT.crit == -9'sd36)   else $error("TEST6 FAIL: crit should be -36, got %0d", UUT.crit);


        // octant 0: (centre_x + offset_x, centre_y + offset_y) = (80+40, 60+1) = (120, 61)
        assert(vga_x == 8'd120)       else $error("TEST6 FAIL: vga_x should be 120, got %0d", vga_x);
        assert(vga_y == 7'd61)        else $error("TEST6 FAIL: vga_y should be 61, got %0d", vga_y);
        assert(vga_plot == 1'b1)      else $error("TEST6 FAIL: vga_plot should be 1, got %0d", vga_plot);

        // TEST 7: done -> wait 
        // use a circle near the edge so some pixels go off screen
        // reset and use centre=(5,5) radius=10
        // octant 3: (5-10, 5+0) = (-5, 5) -> off screen
        start = 0;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n    = 1;
        centre_x = 8'd5;
        centre_y = 7'd5;
        radius   = 8'd10;
        colour   = 3'b010;
        @(posedge clk); #1;

        // wait for clear
        repeat(19200) @(posedge clk); #1;
        assert(state == 2'd1) else $error("TEST7 FAIL: should be in WAIT, got %0d", state);

        // start circle
        start = 1;
        @(posedge clk); #1;
        assert(state == 2'd2)          else $error("TEST7 FAIL: should be in PLOT, got %0d", state);
        assert(UUT.offset_x == 8'd10)  else $error("TEST7 FAIL: offset_x should be 10, got %0d", UUT.offset_x);
        assert(UUT.offset_y == 7'd0)   else $error("TEST7 FAIL: offset_y should be 0, got %0d", UUT.offset_y);

        // octant 0: (5+10, 5+0) = (15, 5) -> on screen
        assert(vga_x == 8'd15)  else $error("TEST7 FAIL: oct0 vga_x should be 15, got %0d", vga_x);
        assert(vga_y == 7'd5)   else $error("TEST7 FAIL: oct0 vga_y should be 5, got %0d", vga_y);
        assert(vga_plot == 1'b1) else $error("TEST7 FAIL: oct0 should be on screen, got %0d", vga_plot);

        // advance to octant 3: (5-10, 5+0) = (-5, 5) -> off screen
        @(posedge clk); #1; // octant 1
        @(posedge clk); #1; // octant 2
        @(posedge clk); #1; // octant 3
        assert(UUT.octant == 3'd3)  else $error("TEST7 FAIL: should be octant 3, got %0d", UUT.octant);
        assert(vga_plot == 1'b0)    else $error("TEST7 FAIL: oct3 should be off screen, got %0d", vga_plot);

        // advance to octant 4: (5-10, 5-0) = (-5, 5) -> off screen
        @(posedge clk); #1;
        assert(UUT.octant == 3'd4)  else $error("TEST7 FAIL: should be octant 4, got %0d", UUT.octant);
        assert(vga_plot == 1'b0)    else $error("TEST7 FAIL: oct4 should be off screen, got %0d", vga_plot);


        // TEST 8: circle completes -> done
        while(done !== 1'b1) begin
            @(posedge clk); #1;
        end
        assert(state == 2'd3)      else $error("TEST8 FAIL: should be in DONE, got %0d", state);
        assert(next_state == 2'd3) else $error("TEST8 FAIL: next_state should be DONE (start=1), got %0d", next_state);
        assert(done == 1'b1)       else $error("TEST8 FAIL: done should be 1, got %0d", done);
        assert(vga_plot == 1'b0)   else $error("TEST8 FAIL: vga_plot should be 0 in DONE, got %0d", vga_plot);

        // deassert start -> back to WAIT
        start = 0;
        #1;
        assert(next_state == 2'd1) else $error("TEST8 FAIL: next_state should be WAIT after ~start, got %0d", next_state);
        @(posedge clk); #1;
        assert(state == 2'd1)      else $error("TEST8 FAIL: should be in WAIT, got %0d", state);
        assert(done == 1'b0)       else $error("TEST8 FAIL: done should be 0, got %0d", done);


        // TEST 9: cycle count
        start = 0;
        rst_n = 0;
        @(posedge clk); #1;
        rst_n    = 1;
        centre_x = 8'd80;
        centre_y = 7'd60;
        radius   = 8'd40;
        colour   = 3'b010;
        @(posedge clk); #1;

        // wait for clear
        repeat(19200) @(posedge clk); #1;
        assert(state == 2'd1) else $error("TEST9 FAIL: should be in WAIT, got %0d", state);

        // start and count cycles
        cycle_count = 0;
        start = 1;
        @(posedge clk); #1;
        assert(state == 2'd2) else $error("TEST9 FAIL: should be in PLOT, got %0d", state);

        while(done !== 1'b1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if(cycle_count > 10000) begin
                $error("TEST9 FAIL: exceeded cycle budget at cycle %0d", cycle_count);
                break;
            end
        end

        // radius=40 circle has roughly 8*40=320 pixels, cycle count =320+10=330
        assert(cycle_count <= 330) else $error("TEST9 FAIL: took %0d cycles,  max is 330 cycles", cycle_count);
        $display("TEST9 PASS: completed in %0d cycles", cycle_count);

        $finish(0);
    end

endmodule: tb_circle