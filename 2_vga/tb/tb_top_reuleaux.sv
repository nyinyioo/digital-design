`timescale 1ns/1ps

module tb_top_reuleaux();

    // --------------------------------------------------------
    // DUT signals
    // --------------------------------------------------------
    logic        CLOCK_50;
    logic [3:0]  KEY;
    logic [9:0]  SW;
    logic [9:0]  LEDR;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [7:0]  VGA_R, VGA_G, VGA_B;
    logic        VGA_HS, VGA_VS, VGA_CLK;
    logic [7:0]  VGA_X;
    logic [6:0]  VGA_Y;
    logic [2:0]  VGA_COLOUR;
    logic        VGA_PLOT;

    // --------------------------------------------------------
    // DUT instantiation
    // --------------------------------------------------------
    top_reuleaux DUT(
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
        // initialise inputs
        KEY  = 4'hF;
        SW   = 10'b0;

        // TEST 1: reset
        KEY[3] = 0;   // assert reset
        @(posedge CLOCK_50); #1;
        assert(VGA_PLOT == 1'b1)   else $error("TEST1 FAIL: vga_plot should be 1 in CLEAR, got %0d", VGA_PLOT);
        assert(VGA_COLOUR == 3'b0) else $error("TEST1 FAIL: colour should be black in CLEAR, got %0d", VGA_COLOUR);
        assert(LEDR[0] == 1'b0)    else $error("TEST1 FAIL: done should be 0 on reset, got %0d", LEDR[0]);
        KEY[3] = 1;    // deassert reset

        // TEST 2: wait for clear to complete
        repeat(19200) @(posedge CLOCK_50); #1;
        assert(VGA_PLOT == 1'b0) else $error("TEST2 FAIL: vga_plot should be 0 in WAIT, got %0d", VGA_PLOT);

        // TEST 3: start -> draw reuleaux
        SW   = 10'b0100000000;  // colour = 3'b010 (green)
        KEY[0] = 0;             // assert start (active-low)
        @(posedge CLOCK_50); #1;
        KEY[0] = 1;             // deassert

        // TEST 4: wait for done
        wait(LEDR[0] == 1'b1);
        assert(LEDR[0] == 1'b1) else $error("TEST4 FAIL: done should be 1, got %0d", LEDR[0]);

        $finish(0);
    end

endmodule: tb_top_reuleaux