`timescale 1ns/1ps
module tb_top_circle();
    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [9:0] LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [7:0] VGA_R, VGA_G, VGA_B;
    logic VGA_HS, VGA_VS, VGA_CLK;
    logic [7:0] VGA_X;
    logic [6:0] VGA_Y;
    logic [2:0] VGA_COLOUR;
    logic VGA_PLOT;

    // cycle counter
    integer cycle_count;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    task3 DUT(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
        .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_CLK(VGA_CLK),
        .VGA_X(VGA_X), .VGA_Y(VGA_Y),
        .VGA_COLOUR(VGA_COLOUR), .VGA_PLOT(VGA_PLOT)
    );

    // --------------------------------------------------------
    // Clock generation -- 20ns
    // --------------------------------------------------------
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;


    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    initial begin
        KEY = 4'hF;
        SW  = 10'b0;

        // TEST 1: reset
        KEY[3] = 0;
        @(posedge CLOCK_50); #1;
        assert(LEDR[0] == 0)       else $error("TEST1 FAIL: done should be 0 on reset, got %0d", LEDR[0]);
        assert(VGA_PLOT == 1)      else $error("TEST1 FAIL: VGA_PLOT should be 1 in CLEAR, got %0d", VGA_PLOT);
        assert(VGA_COLOUR == 3'b0) else $error("TEST1 FAIL: VGA_COLOUR should be black, got %0b", VGA_COLOUR);
        assert(VGA_X == 8'd0)      else $error("TEST1 FAIL: VGA_X should be 0, got %0d", VGA_X);
        assert(VGA_Y == 7'd0)      else $error("TEST1 FAIL: VGA_Y should be 0, got %0d", VGA_Y);
        KEY[3] = 1;
        @(posedge CLOCK_50); #1;

        // TEST 2: clear completes
        assert(VGA_PLOT == 1)      else $error("TEST2 FAIL: VGA_PLOT should be 1 during CLEAR, got %0d", VGA_PLOT);
        assert(VGA_COLOUR == 3'b0) else $error("TEST2 FAIL: VGA_COLOUR should be black during CLEAR, got %0b", VGA_COLOUR);
        repeat(19200) @(posedge CLOCK_50); #1;
        assert(VGA_PLOT == 0)      else $error("TEST2 FAIL: VGA_PLOT should be 0 in WAIT, got %0d", VGA_PLOT);
        assert(LEDR[0] == 0)       else $error("TEST2 FAIL: done should be 0 in WAIT, got %0d", LEDR[0]);

        // TEST 3: start -> circle draws green
        KEY[0] = 0;
        @(posedge CLOCK_50); #1;
        assert(VGA_PLOT == 1)         else $error("TEST3 FAIL: VGA_PLOT should be 1 in PLOT, got %0d", VGA_PLOT);
        assert(VGA_COLOUR == 3'b010)  else $error("TEST3 FAIL: filling black first, got %0b", VGA_COLOUR); 

        // TEST 4: circle pixels are green
        @(posedge CLOCK_50); #1;
        assert(VGA_PLOT == 1)         else $error("TEST4 FAIL: VGA_PLOT should be 1 drawing circle, got %0d", VGA_PLOT); 
        assert(VGA_COLOUR == 3'b010)  else $error("TEST4 FAIL: circle should be green, got %0b", VGA_COLOUR);

        // TEST 5: first circle pixel at (120, 60)
        // octant 0: centre_x + offset_x = 80 + 40 = 120, centre_y + offset_y = 60 + 0 = 60
        assert(VGA_X == 8'd120) else $error("TEST5 FAIL: first pixel x should be 120, got %0d", VGA_X); 
        assert(VGA_Y == 7'd60)  else $error("TEST5 FAIL: first pixel y should be 60, got %0d", VGA_Y); 

        // TEST 6: done asserted after circle completes
        while(LEDR[0] !== 1'b1) begin
            @(posedge CLOCK_50); #1;
        end
        assert(LEDR[0] == 1)   else $error("TEST6 FAIL: done should be 1, got %0d", LEDR[0]);
        assert(VGA_PLOT == 0)  else $error("TEST6 FAIL: VGA_PLOT should be 0 in DONE, got %0d", VGA_PLOT);

        // TEST 7: done -> wait on ~start
        KEY[0] = 1;
        @(posedge CLOCK_50); #1;
        assert(LEDR[0] == 0)  else $error("TEST7 FAIL: done should be 0 in WAIT, got %0d", LEDR[0]);
        assert(VGA_PLOT == 0) else $error("TEST7 FAIL: VGA_PLOT should be 0 in WAIT, got %0d", VGA_PLOT);

        // TEST 8: cycle budget
        // budget = 19200 (fillscreen) + circle_budget (8*40+10=330) + 10 = 19540
        cycle_count = 0;
        KEY[0] = 0;
        @(posedge CLOCK_50); #1;

        while(LEDR[0] !== 1'b1) begin
            @(posedge CLOCK_50); #1;
            cycle_count = cycle_count + 1;
            if(cycle_count > 19540) begin
                $error("TEST8 FAIL: exceeded cycle budget at cycle %0d", cycle_count);
                break;
            end
        end
        assert(cycle_count <= 19540) else $error("TEST8 FAIL: took %0d cycles, max 19540", cycle_count);
        $display("TEST8 PASS: completed in %0d cycles", cycle_count);

        $finish(0);
    end

endmodule: tb_rtl_task3