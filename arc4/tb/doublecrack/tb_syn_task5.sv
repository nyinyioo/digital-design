`timescale 1ps/1ps

module tb_syn_task5();

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
    // load the ciphertext directly into the top level CT memory using the proper synthesized hierarchy
    task write_ct(input [7:0] addr, input [7:0] data);
        begin
            DUT.\ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[addr] = data;
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
    // for synthesized tb we will focus on observable top level behavior
    // task5 should keep the displays blank while computing and then eventually show the key
    task wait_for_task5_done;
        integer cycles;
        begin
            cycles = 0;

            // first allow some time for the search to begin while making sure we still stay blank early on
            repeat(20) @(posedge CLOCK_50);

            // now wait until the displays are no longer blank
            while ((HEX0 == seg7_blank()) &&
                   (HEX1 == seg7_blank()) &&
                   (HEX2 == seg7_blank()) &&
                   (HEX3 == seg7_blank()) &&
                   (HEX4 == seg7_blank()) &&
                   (HEX5 == seg7_blank()) &&
                   cycles < 60000) begin
                @(posedge CLOCK_50);
                cycles = cycles + 1;
            end

            assert(cycles < 60000) else $fatal("timeout waiting for task5 displays to update");
        end
    endtask

    // Test stimulation
    initial begin
        $display("=== TB: SYN task5 ===");

        SW = 10'd0;
        KEY = 4'hF;

        // test 1
        // CODE vector should finish with key 000001
        KEY[3] = 1'b0;

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

        // displays should still be blank while we're early in the search
        repeat(20) @(posedge CLOCK_50);
        #1;
        check_displays_blank();

        // wait for the search to finish and then check the displayed key
        wait_for_task5_done();
        #1;
        check_displays_show_key(KEY_CODE);
        assert(LEDR == 10'h000) else $error("Expected LEDR to stay 0");

        // test 2
        // TEST vector should finish with key 000002
        // rerun task5 after another reset
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

        $display("=== tb_syn_task5 PASSED ===");
        $finish(0);
    end

endmodule : tb_syn_task5