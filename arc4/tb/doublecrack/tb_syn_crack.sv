`timescale 1ps/1ps

module tb_syn_crack();

    // DUT signals
    logic clk, rst_n, en, rdy;
    logic [23:0] key;
    logic key_valid;
    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    // Task 5 extra ports on crack
    logic [23:0] start_key;
    logic [23:0] key_step;
    logic [7:0] pt_rd_addr;
    logic [7:0] pt_rddata;

    // Test vectors
    // vector 1
    // plaintext is "CODE"
    // this one should crack with key 24'h000001
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
    // this one should crack with key 24'h000002
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
    crack DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .key_valid(key_valid),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .start_key(start_key),
        .key_step(key_step),
        .pt_rd_addr(pt_rd_addr),
        .pt_rddata(pt_rddata)
    );

    // CT is external to crack so we give the DUT a real ct_mem
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
    // synthesized tb so we use the post synthesis hierarchy paths

    task write_ct(input [7:0] addr, input [7:0] data);
        begin
            \ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[addr] = data;
        end
    endtask

    task read_ct(input [7:0] addr, output [7:0] data);
        begin
            data = \ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[addr];
        end
    endtask

    task read_pt(input [7:0] addr, output [7:0] data);
        begin
            data = DUT.\pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[addr];
        end
    endtask

    // load the ciphertext for the CODE vector
    task load_code_ciphertext;
        begin
            write_ct(8'd0, CODE_CT_0);
            write_ct(8'd1, CODE_CT_1);
            write_ct(8'd2, CODE_CT_2);
            write_ct(8'd3, CODE_CT_3);
            write_ct(8'd4, CODE_CT_4);
        end
    endtask

    // load the ciphertext for the TEST vector
    task load_test_ciphertext;
        begin
            write_ct(8'd0, TEST_CT_0);
            write_ct(8'd1, TEST_CT_1);
            write_ct(8'd2, TEST_CT_2);
            write_ct(8'd3, TEST_CT_3);
            write_ct(8'd4, TEST_CT_4);
        end
    endtask

    // quick sanity check for CODE ciphertext
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

    // quick sanity check for TEST ciphertext
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

    // check that PT contains the length-prefixed plaintext "CODE"
    task check_plaintext_code;
        logic [7:0] data;
        begin
            read_pt(8'd0, data);
            assert(data == CODE_PT_0) else $error("CODE pt[0] mismatch expected %02h got %02h", CODE_PT_0, data);

            read_pt(8'd1, data);
            assert(data == CODE_PT_1) else $error("CODE pt[1] mismatch expected %02h got %02h", CODE_PT_1, data);

            read_pt(8'd2, data);
            assert(data == CODE_PT_2) else $error("CODE pt[2] mismatch expected %02h got %02h", CODE_PT_2, data);

            read_pt(8'd3, data);
            assert(data == CODE_PT_3) else $error("CODE pt[3] mismatch expected %02h got %02h", CODE_PT_3, data);

            read_pt(8'd4, data);
            assert(data == CODE_PT_4) else $error("CODE pt[4] mismatch expected %02h got %02h", CODE_PT_4, data);
        end
    endtask

    // check that PT contains the length-prefixed plaintext "TEST"
    task check_plaintext_test;
        logic [7:0] data;
        begin
            read_pt(8'd0, data);
            assert(data == TEST_PT_0) else $error("TEST pt[0] mismatch expected %02h got %02h", TEST_PT_0, data);

            read_pt(8'd1, data);
            assert(data == TEST_PT_1) else $error("TEST pt[1] mismatch expected %02h got %02h", TEST_PT_1, data);

            read_pt(8'd2, data);
            assert(data == TEST_PT_2) else $error("TEST pt[2] mismatch expected %02h got %02h", TEST_PT_2, data);

            read_pt(8'd3, data);
            assert(data == TEST_PT_3) else $error("TEST pt[3] mismatch expected %02h got %02h", TEST_PT_3, data);

            read_pt(8'd4, data);
            assert(data == TEST_PT_4) else $error("TEST pt[4] mismatch expected %02h got %02h", TEST_PT_4, data);
        end
    endtask

    // ============== Handshake helper tasks =============
    // pulse en for one cycle and then deassert it
    task start_crack_once;
        begin
            @(negedge clk);
            en = 1'b1;
            @(posedge clk);
            #1;
            @(negedge clk);
            en = 1'b0;
        end
    endtask

    // wait for crack to go busy and then later come back to ready
    task wait_for_crack_done;
        integer cycles;
        begin
            cycles = 0;

            // first make sure crack actually left the ready state
            while (rdy !== 1'b0 && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal("crack never left ready after request");

            cycles = 0;

            // now wait until the search finishes
            while (rdy !== 1'b1 && cycles < 20000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal("timeout waiting for crack to finish");
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
        $display("=== TB: SYN crack task5 ===");

        en = 1'b0;
        rst_n = 1'b1;
        start_key = 24'd0;
        key_step = 24'd1;
        pt_rd_addr = 8'd0;

        // wait a bit before directly touching the memory model
        #10;

        // test 1
        // normal task4 style search starting at 0 stepping by 1
        // should find the CODE vector at key 1
        load_code_ciphertext();
        check_code_ciphertext_loaded();
        apply_reset();

        assert(rdy) else $error("Expected rdy=1 after reset before starting test 1");
        assert(!key_valid) else $error("Expected key_valid=0 before starting test 1");

        start_key = 24'h000000;
        key_step = 24'd1;

        start_crack_once();
        wait_for_crack_done();

        assert(key_valid) else $error("Expected key_valid=1 for test 1");
        assert(key == KEY_CODE) else $error("Expected key=%06h for test 1 got %06h", KEY_CODE, key);
        check_plaintext_code();

        // test 2
        // odd-only search starting at 1 stepping by 2
        // should also find the CODE vector immediately on the odd side
        load_code_ciphertext();
        check_code_ciphertext_loaded();
        apply_reset();

        assert(rdy) else $error("Expected rdy=1 after reset before starting test 2");
        assert(!key_valid) else $error("Expected key_valid=0 before starting test 2");

        start_key = 24'h000001;
        key_step = 24'd2;

        start_crack_once();
        wait_for_crack_done();

        assert(key_valid) else $error("Expected key_valid=1 for test 2");
        assert(key == KEY_CODE) else $error("Expected key=%06h for test 2 got %06h", KEY_CODE, key);
        check_plaintext_code();

        // test 3
        // even-only search starting at 0 stepping by 2
        // should find the TEST vector at key 2
        load_test_ciphertext();
        check_test_ciphertext_loaded();
        apply_reset();

        assert(rdy) else $error("Expected rdy=1 after reset before starting test 3");
        assert(!key_valid) else $error("Expected key_valid=0 before starting test 3");

        start_key = 24'h000000;
        key_step = 24'd2;

        start_crack_once();
        wait_for_crack_done();

        assert(key_valid) else $error("Expected key_valid=1 for test 3");
        assert(key == KEY_TEST) else $error("Expected key=%06h for test 3 got %06h", KEY_TEST, key);
        check_plaintext_test();

        $display("=== tb_syn_crack PASSED ===");
        $finish(0);
    end

endmodule : tb_syn_crack