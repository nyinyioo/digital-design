`timescale 1ps/1ps

module tb_rtl_doublecrack();

    // DUT signals
    logic clk, rst_n, en, rdy;
    logic [23:0] key;
    logic key_valid;
    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    // Test vectors

    // vector 1
    // plaintext is "CODE"
    // winning key is 24'h000001 so c2 should be the winning core
    localparam logic [23:0] KEY_CODE = 24'h000001;

    localparam logic [7:0] CODE_CT_0 = 8'h04;
    localparam logic [7:0] CODE_CT_1 = 8'h47;
    localparam logic [7:0] CODE_CT_2 = 8'h00;
    localparam logic [7:0] CODE_CT_3 = 8'h10;
    localparam logic [7:0] CODE_CT_4 = 8'h3E;

    localparam logic [7:0] CODE_PT_0 = 8'h04;
    localparam logic [7:0] CODE_PT_1 = 8'h43; // C
    localparam logic [7:0] CODE_PT_2 = 8'h4F; // O
    localparam logic [7:0] CODE_PT_3 = 8'h44; // D
    localparam logic [7:0] CODE_PT_4 = 8'h45; // E

    // vector 2
    // plaintext is "TEST"
    // winning key is 24'h000002 so c1 should be the winning core
    localparam logic [23:0] KEY_TEST = 24'h000002;

    localparam logic [7:0] TEST_CT_0 = 8'h04;
    localparam logic [7:0] TEST_CT_1 = 8'h10;
    localparam logic [7:0] TEST_CT_2 = 8'hF9;
    localparam logic [7:0] TEST_CT_3 = 8'h5F;
    localparam logic [7:0] TEST_CT_4 = 8'hFE;

    localparam logic [7:0] TEST_PT_0 = 8'h04;
    localparam logic [7:0] TEST_PT_1 = 8'h54; // T
    localparam logic [7:0] TEST_PT_2 = 8'h45; // E
    localparam logic [7:0] TEST_PT_3 = 8'h53; // S
    localparam logic [7:0] TEST_PT_4 = 8'h54; // T

    // DUT
    doublecrack DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .key_valid(key_valid),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata)
    );

    // external CT memory
    ct_mem ct(
        .address(ct_addr),
        .clock(clk),
        .data(8'd0),
        .wren(1'b0),
        .q(ct_rddata)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============== Memory helper tasks =============
    // direct rtl hierarchy access for the top-level CT memory
    // and for the shared / private PT memories inside doublecrack
    task write_ct(input [7:0] addr, input [7:0] data);
        begin
            ct.altsyncram_component.m_default.altsyncram_inst.mem_data[addr] = data;
        end
    endtask

    task read_ct(input [7:0] addr, output [7:0] data);
        begin
            data = ct.altsyncram_component.m_default.altsyncram_inst.mem_data[addr];
        end
    endtask

    task read_shared_pt(input [7:0] addr, output [7:0] data);
        begin
            data = DUT.pt.altsyncram_component.m_default.altsyncram_inst.mem_data[addr];
        end
    endtask

    task read_c1_pt(input [7:0] addr, output [7:0] data);
        begin
            data = DUT.c1.pt.altsyncram_component.m_default.altsyncram_inst.mem_data[addr];
        end
    endtask

    task read_c2_pt(input [7:0] addr, output [7:0] data);
        begin
            data = DUT.c2.pt.altsyncram_component.m_default.altsyncram_inst.mem_data[addr];
        end
    endtask

    // load the CODE ciphertext
    task load_code_ciphertext;
        begin
            write_ct(8'd0, CODE_CT_0);
            write_ct(8'd1, CODE_CT_1);
            write_ct(8'd2, CODE_CT_2);
            write_ct(8'd3, CODE_CT_3);
            write_ct(8'd4, CODE_CT_4);
        end
    endtask

    // load the TEST ciphertext
    task load_test_ciphertext;
        begin
            write_ct(8'd0, TEST_CT_0);
            write_ct(8'd1, TEST_CT_1);
            write_ct(8'd2, TEST_CT_2);
            write_ct(8'd3, TEST_CT_3);
            write_ct(8'd4, TEST_CT_4);
        end
    endtask

    // sanity check for CODE ciphertext
    task check_code_ciphertext_loaded;
        logic [7:0] data;
        begin
            read_ct(8'd0, data);
            assert(data == CODE_CT_0) else $error("CODE ct[0] mismatch expected %02h got %02h", CODE_CT_0, data);

            read_ct(8'd1, data);
            assert(data == CODE_CT_1) else $error("CODE ct[1] mismatch expected %02h got %02h", CODE_CT_1, data);

            read_ct(8'd2, data);
            assert(data == CODE_CT_2) else $error("CODE ct[2] mismatch expected %02h got %02h", CODE_CT_2, data);

            read_ct(8'd3, data);
            assert(data == CODE_CT_3) else $error("CODE ct[3] mismatch expected %02h got %02h", CODE_CT_3, data);

            read_ct(8'd4, data);
            assert(data == CODE_CT_4) else $error("CODE ct[4] mismatch expected %02h got %02h", CODE_CT_4, data);
        end
    endtask

    // sanity check for TEST ciphertext
    task check_test_ciphertext_loaded;
        logic [7:0] data;
        begin
            read_ct(8'd0, data);
            assert(data == TEST_CT_0) else $error("TEST ct[0] mismatch expected %02h got %02h", TEST_CT_0, data);

            read_ct(8'd1, data);
            assert(data == TEST_CT_1) else $error("TEST ct[1] mismatch expected %02h got %02h", TEST_CT_1, data);

            read_ct(8'd2, data);
            assert(data == TEST_CT_2) else $error("TEST ct[2] mismatch expected %02h got %02h", TEST_CT_2, data);

            read_ct(8'd3, data);
            assert(data == TEST_CT_3) else $error("TEST ct[3] mismatch expected %02h got %02h", TEST_CT_3, data);

            read_ct(8'd4, data);
            assert(data == TEST_CT_4) else $error("TEST ct[4] mismatch expected %02h got %02h", TEST_CT_4, data);
        end
    endtask

    // check that the shared PT memory contains "CODE"
    task check_shared_pt_code;
        logic [7:0] data;
        begin
            read_shared_pt(8'd0, data);
            assert(data == CODE_PT_0) else $error("shared CODE pt[0] mismatch expected %02h got %02h", CODE_PT_0, data);

            read_shared_pt(8'd1, data);
            assert(data == CODE_PT_1) else $error("shared CODE pt[1] mismatch expected %02h got %02h", CODE_PT_1, data);

            read_shared_pt(8'd2, data);
            assert(data == CODE_PT_2) else $error("shared CODE pt[2] mismatch expected %02h got %02h", CODE_PT_2, data);

            read_shared_pt(8'd3, data);
            assert(data == CODE_PT_3) else $error("shared CODE pt[3] mismatch expected %02h got %02h", CODE_PT_3, data);

            read_shared_pt(8'd4, data);
            assert(data == CODE_PT_4) else $error("shared CODE pt[4] mismatch expected %02h got %02h", CODE_PT_4, data);
        end
    endtask

    // check that c2.pt contains "CODE"
    task check_c2_pt_code;
        logic [7:0] data;
        begin
            read_c2_pt(8'd0, data);
            assert(data == CODE_PT_0) else $error("c2 CODE pt[0] mismatch expected %02h got %02h", CODE_PT_0, data);

            read_c2_pt(8'd1, data);
            assert(data == CODE_PT_1) else $error("c2 CODE pt[1] mismatch expected %02h got %02h", CODE_PT_1, data);

            read_c2_pt(8'd2, data);
            assert(data == CODE_PT_2) else $error("c2 CODE pt[2] mismatch expected %02h got %02h", CODE_PT_2, data);

            read_c2_pt(8'd3, data);
            assert(data == CODE_PT_3) else $error("c2 CODE pt[3] mismatch expected %02h got %02h", CODE_PT_3, data);

            read_c2_pt(8'd4, data);
            assert(data == CODE_PT_4) else $error("c2 CODE pt[4] mismatch expected %02h got %02h", CODE_PT_4, data);
        end
    endtask

    // check that the shared PT memory contains "TEST"
    task check_shared_pt_test;
        logic [7:0] data;
        begin
            read_shared_pt(8'd0, data);
            assert(data == TEST_PT_0) else $error("shared TEST pt[0] mismatch expected %02h got %02h", TEST_PT_0, data);

            read_shared_pt(8'd1, data);
            assert(data == TEST_PT_1) else $error("shared TEST pt[1] mismatch expected %02h got %02h", TEST_PT_1, data);

            read_shared_pt(8'd2, data);
            assert(data == TEST_PT_2) else $error("shared TEST pt[2] mismatch expected %02h got %02h", TEST_PT_2, data);

            read_shared_pt(8'd3, data);
            assert(data == TEST_PT_3) else $error("shared TEST pt[3] mismatch expected %02h got %02h", TEST_PT_3, data);

            read_shared_pt(8'd4, data);
            assert(data == TEST_PT_4) else $error("shared TEST pt[4] mismatch expected %02h got %02h", TEST_PT_4, data);
        end
    endtask

    // check that c1.pt contains "TEST"
    task check_c1_pt_test;
        logic [7:0] data;
        begin
            read_c1_pt(8'd0, data);
            assert(data == TEST_PT_0) else $error("c1 TEST pt[0] mismatch expected %02h got %02h", TEST_PT_0, data);

            read_c1_pt(8'd1, data);
            assert(data == TEST_PT_1) else $error("c1 TEST pt[1] mismatch expected %02h got %02h", TEST_PT_1, data);

            read_c1_pt(8'd2, data);
            assert(data == TEST_PT_2) else $error("c1 TEST pt[2] mismatch expected %02h got %02h", TEST_PT_2, data);

            read_c1_pt(8'd3, data);
            assert(data == TEST_PT_3) else $error("c1 TEST pt[3] mismatch expected %02h got %02h", TEST_PT_3, data);

            read_c1_pt(8'd4, data);
            assert(data == TEST_PT_4) else $error("c1 TEST pt[4] mismatch expected %02h got %02h", TEST_PT_4, data);
        end
    endtask

    // ============== Handshake helper tasks =============
    // pulse en for one cycle and then deassert it
    task start_doublecrack_once;
        begin
            @(negedge clk);
            en = 1'b1;
            @(posedge clk);
            #1;
            @(negedge clk);
            en = 1'b0;
        end
    endtask

    // wait for doublecrack to go busy and then later come back to ready
    task wait_for_doublecrack_done;
        integer cycles;
        begin
            cycles = 0;

            // first make sure the module really left the ready state
            while (rdy !== 1'b0 && cycles < 40) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal("doublecrack never left ready after request");

            cycles = 0;

            // now wait until the whole search and PT copy finish
            while (rdy !== 1'b1 && cycles < 40000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal("timeout waiting for doublecrack to finish");
        end
    endtask

    // apply one clean synchronous active-low reset pulse
    task apply_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            @(posedge clk);
            #1;
            @(negedge clk);
            rst_n = 1'b1;
            @(posedge clk);
            #1;
        end
    endtask

    // ============== Actual tests =============
    initial begin
        $display("=== TB: RTL doublecrack ===");

        en = 1'b0;
        rst_n = 1'b1;

        // wait a bit before directly touching the memory model
        #10;

        // test 1
        // CODE vector should be found by the odd-key side so c2 should win
        // shared PT and c2.pt should both contain the final plaintext
        load_code_ciphertext();
        check_code_ciphertext_loaded();
        apply_reset();

        assert(rdy) else $error("Expected rdy=1 after reset before starting test 1");
        assert(!key_valid) else $error("Expected key_valid=0 before starting test 1");

        start_doublecrack_once();
        wait_for_doublecrack_done();

        assert(key_valid) else $error("Expected key_valid=1 for test 1");
        assert(key == KEY_CODE) else $error("Expected key=%06h for test 1 got %06h", KEY_CODE, key);

        // winner should be c2 here since the winning key is odd
        assert(!DUT.winner_is_c1) else $error("Expected c2 to be the winning core for CODE vector");

        check_shared_pt_code();
        check_c2_pt_code();

        // test 2
        // TEST vector should be found by the even-key side so c1 should win
        // shared PT and c1.pt should both contain the final plaintext
        load_test_ciphertext();
        check_test_ciphertext_loaded();
        apply_reset();

        assert(rdy) else $error("Expected rdy=1 after reset before starting test 2");
        assert(!key_valid) else $error("Expected key_valid=0 before starting test 2");

        start_doublecrack_once();
        wait_for_doublecrack_done();

        assert(key_valid) else $error("Expected key_valid=1 for test 2");
        assert(key == KEY_TEST) else $error("Expected key=%06h for test 2 got %06h", KEY_TEST, key);

        // winner should be c1 here since the winning key is even
        assert(DUT.winner_is_c1) else $error("Expected c1 to be the winning core for TEST vector");

        check_shared_pt_test();
        check_c1_pt_test();

        $display("=== tb_rtl_doublecrack PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_doublecrack