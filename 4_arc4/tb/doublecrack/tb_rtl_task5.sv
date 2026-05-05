`timescale 1ps/1ps

module tb_rtl_task5();

    // DUT signals
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [9:0] LEDR;

    // Test vectors
    // We will use the same short vectors as the crack and doublecrack benches
    // vector 1 is CODE and should crack with key 24'h000001
    // vector 2 is TEST and should crack with key 24'h000002
    localparam logic [23:0] KEY_CODE = 24'h000001;
    localparam logic [23:0] KEY_TEST = 24'h000002;

    localparam logic [7:0] CODE_CT_0 = 8'h04;
    localparam logic [7:0] CODE_CT_1 = 8'h47;
    localparam logic [7:0] CODE_CT_2 = 8'h00;
    localparam logic [7:0] CODE_CT_3 = 8'h10;
    localparam logic [7:0] CODE_CT_4 = 8'h3E;

    localparam logic [7:0] TEST_CT_0 = 8'h04;
    localparam logic [7:0] TEST_CT_1 = 8'h10;
    localparam logic [7:0] TEST_CT_2 = 8'hF9;
    localparam logic [7:0] TEST_CT_3 = 8'h5F;
    localparam logic [7:0] TEST_CT_4 = 8'hFE;

    // DUT
    task5 DUT(
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
    // encodings used inside task5
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

    task load_code_ciphertext;
        begin
            write_ct(8'd0, CODE_CT_0);
            write_ct(8'd1, CODE_CT_1);
            write_ct(8'd2, CODE_CT_2);
            write_ct(8'd3, CODE_CT_3);
            write_ct(8'd4, CODE_CT_4);
        end
    endtask

    task load_test_ciphertext;
        begin
            write_ct(8'd0, TEST_CT_0);
            write_ct(8'd1, TEST_CT_1);
            write_ct(8'd2, TEST_CT_2);
            write_ct(8'd3, TEST_CT_3);
            write_ct(8'd4, TEST_CT_4);
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

    // check that the 24 bit key is displayed properly left to right
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

    // wait helper
    // task5 should automatically start doublecrack once after reset
    // so this task waits until that full process finishes
    task wait_for_task5_done;
        integer cycles;
        begin
            cycles = 0;

            // first wait until task5 has actually launched doublecrack
            while (DUT.started !== 1'b1 && cycles < 20) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.started == 1'b1) else $fatal("task5 never started doublecrack");

            cycles = 0;
            // now wait until doublecrack goes busy
            while (DUT.dc.rdy !== 1'b0 && cycles < 40) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.dc.rdy == 1'b0) else $fatal("doublecrack never left ready state inside task5");

            cycles = 0;
            // then wait for doublecrack to finish and come back to ready
            while (DUT.dc.rdy !== 1'b1 && cycles < 50000) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end
            assert(DUT.dc.rdy == 1'b1) else $fatal("timeout waiting for task5 to finish");
        end
    endtask

    // Test stimulation
    initial begin
        $display("=== TB: RTL task5 ===");

        SW = 10'd0;
        KEY = 4'hF;

        // test 1
        // CODE vector should finish with key 000001
        // displays should stay blank while running then show the key

        // hold reset low first
        KEY[3] = 1'b0;

        // load the CODE ciphertext before releasing reset
        #10;
        load_code_ciphertext();

        // while still in reset the displays should be blank
        @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        // release reset
        @(negedge CLOCK_50);
        KEY[3] = 1'b1;
        @(posedge CLOCK_50);
        #1;

        // displays should still be blank while task5 is still computing
        repeat(20) @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        // wait until the full search finishes
        wait_for_task5_done();
        #1;

        // check the key is being displayed properly
        check_displays_show_key(KEY_CODE);
        assert(LEDR == 10'h000) else $error("Expected LEDR to stay 0");

        // test 2
        // TEST vector should finish with key 000002
        // rerun task5 after another reset and make sure it still works
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;

        #10;
        load_test_ciphertext();

        @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        @(negedge CLOCK_50);
        KEY[3] = 1'b1;
        @(posedge CLOCK_50);
        #1;

        repeat(20) @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        wait_for_task5_done();
        #1;

        check_displays_show_key(KEY_TEST);
        assert(LEDR == 10'h000) else $error("Expected LEDR to stay 0");

        // forced display checks
        // these let us verify the blank case, success example, and dash case
        // without needing a huge full-key-space simulation

        // forced blank case before start
        force DUT.started = 1'b0;
        #1;
        check_displays_blank();
        release DUT.started;
        #1;

        // forced computing case should also stay blank
        force DUT.started = 1'b1;
        force DUT.dc_rdy = 1'b0;
        #1;
        check_displays_blank();
        release DUT.started;
        release DUT.dc_rdy;
        #1;

        // forced success example from the handout to verify left-to-right nibble ordering
        force DUT.started = 1'b1;
        force DUT.dc_rdy = 1'b1;
        force DUT.dc_key_valid = 1'b1;
        force DUT.dc_key = 24'h123456;
        #1;
        check_displays_show_key(24'h123456);
        release DUT.started;
        release DUT.dc_rdy;
        release DUT.dc_key_valid;
        release DUT.dc_key;
        #1;

        // forced failure case should show dashes
        force DUT.started = 1'b1;
        force DUT.dc_rdy = 1'b1;
        force DUT.dc_key_valid = 1'b0;
        #1;
        check_displays_dash();
        release DUT.started;
        release DUT.dc_rdy;
        release DUT.dc_key_valid;
        #1;

        $display("=== tb_rtl_task5 PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_task5