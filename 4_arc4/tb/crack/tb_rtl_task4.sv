`timescale 1ps/1ps

module tb_rtl_top_crack();

    // DUT signals
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [9:0] LEDR;

    // Test vector
    // same ciphertext used in rtl_crack plain text word is "CODE" 
    localparam logic [23:0] EXPECTED_KEY = 24'h000001;

    localparam logic [7:0] CT_0 = 8'h04;
    localparam logic [7:0] CT_1 = 8'h47;
    localparam logic [7:0] CT_2 = 8'h00;
    localparam logic [7:0] CT_3 = 8'h10;
    localparam logic [7:0] CT_4 = 8'h3E;

    // DUT
    top_crack DUT(
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR)
    );

    // Clock generation
    initial begin
        CLOCK_50 = 1'b0;
        forever #5 CLOCK_50 = ~CLOCK_50;
    end

    // Display helper functions
    // These helper functions mirror the exact active-low 7-segment
    // encodings used inside task4
    function automatic logic [6:0] seg7_hex(input logic [3:0] nibble);
        begin
            case (nibble)
                4'h0: seg7_hex = 7'h40;
                4'h1: seg7_hex = 7'h79;
                4'h2: seg7_hex = 7'h24;
                4'h3: seg7_hex = 7'h30;
                4'h4: seg7_hex = 7'h19;
                4'h5: seg7_hex = 7'h12;
                4'h6: seg7_hex = 7'h02;
                4'h7: seg7_hex = 7'h78;
                4'h8: seg7_hex = 7'h00;
                4'h9: seg7_hex = 7'h10;
                4'hA: seg7_hex = 7'h08;
                4'hB: seg7_hex = 7'h03;
                4'hC: seg7_hex = 7'h46;
                4'hD: seg7_hex = 7'h21;
                4'hE: seg7_hex = 7'h06;
                4'hF: seg7_hex = 7'h0E;
                default: seg7_hex = 7'h7F;
            endcase
        end
    endfunction

    // all segments off
    function automatic logic [6:0] seg7_blank();
        begin
            seg7_blank = 7'h7F;
        end
    endfunction

    // dash pattern
    function automatic logic [6:0] seg7_dash();
        begin
            seg7_dash = 7'h3F;
        end
    endfunction

    // Memory helper tasks
    // load the ciphertext directly into the top level CT memory using the proper rtl hierarchy 
    task write_ct(input [7:0] addr, input [7:0] data);
        begin
            DUT.ct.altsyncram_component.m_default.altsyncram_inst.mem_data[addr] = data;
        end
    endtask

    task load_test_ciphertext;
        begin
            write_ct(8'd0, CT_0);
            write_ct(8'd1, CT_1);
            write_ct(8'd2, CT_2);
            write_ct(8'd3, CT_3);
            write_ct(8'd4, CT_4);
        end
    endtask

    // Display checking tasks
    task check_displays_blank;
        begin
            assert(HEX0 == seg7_blank()) else $error("HEX0 expected blank got %02h", HEX0);
            assert(HEX1 == seg7_blank()) else $error("HEX1 expected blank got %02h", HEX1);
            assert(HEX2 == seg7_blank()) else $error("HEX2 expected blank got %02h", HEX2);
            assert(HEX3 == seg7_blank()) else $error("HEX3 expected blank got %02h", HEX3);
            assert(HEX4 == seg7_blank()) else $error("HEX4 expected blank got %02h", HEX4);
            assert(HEX5 == seg7_blank()) else $error("HEX5 expected blank got %02h", HEX5);
        end
    endtask

    task check_displays_dash;
        begin
            assert(HEX0 == seg7_dash()) else $error("HEX0 expected dash got %02h", HEX0);
            assert(HEX1 == seg7_dash()) else $error("HEX1 expected dash got %02h", HEX1);
            assert(HEX2 == seg7_dash()) else $error("HEX2 expected dash got %02h", HEX2);
            assert(HEX3 == seg7_dash()) else $error("HEX3 expected dash got %02h", HEX3);
            assert(HEX4 == seg7_dash()) else $error("HEX4 expected dash got %02h", HEX4);
            assert(HEX5 == seg7_dash()) else $error("HEX5 expected dash got %02h", HEX5);
        end
    endtask

   
    // Check that the 24 bit key is displayed right 
    task check_displays_show_key(input [23:0] expected_key);
        begin
            assert(HEX5 == seg7_hex(expected_key[23:20])) else $error("HEX5 mismatch");
            assert(HEX4 == seg7_hex(expected_key[19:16])) else $error("HEX4 mismatch");
            assert(HEX3 == seg7_hex(expected_key[15:12])) else $error("HEX3 mismatch");
            assert(HEX2 == seg7_hex(expected_key[11:8])) else $error("HEX2 mismatch");
            assert(HEX1 == seg7_hex(expected_key[7:4])) else $error("HEX1 mismatch");
            assert(HEX0 == seg7_hex(expected_key[3:0])) else $error("HEX0 mismatch");
        end
    endtask

    // End-to-end wait helper
    // task4 starts crack once right after reset so this task will help us wait for the whole process
    // to complete
    task wait_for_task4_done;
        integer cycles;
        begin
            cycles = 0;

            // First wait until t4 has actually launched crack 
            while (DUT.started !== 1'b1 && cycles < 20) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.started == 1'b1) else $fatal("task4 never started crack");

            cycles = 0;
            // now wait until crack goes busy 
            while (DUT.c.rdy !== 1'b0 && cycles < 20) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.c.rdy == 1'b0) else $fatal("crack never left ready state inside task4");

            cycles = 0;
            // then wait for crack to finish and come back to rdy 
            while (DUT.c.rdy !== 1'b1 && cycles < 10000) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.c.rdy == 1'b1) else $fatal("timeout waiting for task4 to finish");
        end
    endtask


    // Test stimulation 
    initial begin
        $display("=== TB: RTL task4 ===");

        SW = 10'd0;
        KEY = 4'hF;

        // hold reset low first
        KEY[3] = 1'b0;

       
        // load the "CODE" ciphertext before releasing reset this way the CT memory already contains the message by the time task4 
        // automatically launches crack
        #10;
        load_test_ciphertext();

        // while still in reset the displays should be blank
        @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        // release reset
        @(negedge CLOCK_50);
        KEY[3] = 1'b1;
        @(posedge CLOCK_50);
        #1;

       
        // displays should still be blank while we're still early in the research 
        repeat(20) @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        // wait until the full search finishes for this short test vector
        wait_for_task4_done();
        #1;

        // check the key is being displayed properly
        check_displays_show_key(EXPECTED_KEY);
        assert(LEDR == 10'h000) else $error("Expected LEDR to stay 0");

       

        // now we will force the diplay logic into the cases mentioned in the read me 
        // forced blank case before start
        force DUT.started = 1'b0;
        #1;
        check_displays_blank();
        release DUT.started;
        #1;

        // forced computing case should also stay blank
        force DUT.started = 1'b1;
        force DUT.crack_rdy = 1'b0;
        #1;
        check_displays_blank();
        release DUT.started;
        release DUT.crack_rdy;
        #1;

        // forced success example from the handout to verify left-to-right nibble ordering
        force DUT.started = 1'b1;
        force DUT.crack_rdy = 1'b1;
        force DUT.crack_key_valid = 1'b1;
        force DUT.crack_key = 24'h123456;
        #1;
        check_displays_show_key(24'h123456);
        release DUT.started;
        release DUT.crack_rdy;
        release DUT.crack_key_valid;
        release DUT.crack_key;
        #1;

        // forced failure case should show dashes
        force DUT.started = 1'b1;
        force DUT.crack_rdy = 1'b1;
        force DUT.crack_key_valid = 1'b0;
        #1;
        check_displays_dash();
        release DUT.started;
        release DUT.crack_rdy;
        release DUT.crack_key_valid;
        #1;

        $display("=== tb_rtl_task4 PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_top_crack