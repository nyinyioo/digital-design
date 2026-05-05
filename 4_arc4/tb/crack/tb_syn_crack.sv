`timescale 1ps/1ps

module tb_syn_crack();

    // DUT signals
    logic clk, rst_n, en, rdy, key_valid;
    logic [23:0] key;
    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;

    // Test vector
    // We will use a small wining key here, our plaintext word will be CODE
    // so pt[0] = 4, pt[1] = "C" and so on
    // also note that the encrypted bytes were chosen so that key 24'h000000 fails and key 24'h000001 succeeds
    // so we can check the functionality works for a wrong key
    localparam logic [23:0] EXPECTED_KEY = 24'h000001;

    localparam logic [7:0] CT_0 = 8'h04;
    localparam logic [7:0] CT_1 = 8'h47;
    localparam logic [7:0] CT_2 = 8'h00;
    localparam logic [7:0] CT_3 = 8'h10;
    localparam logic [7:0] CT_4 = 8'h3E;

    localparam logic [7:0] PT_0 = 8'h04;
    localparam logic [7:0] PT_1 = 8'h43; // C
    localparam logic [7:0] PT_2 = 8'h4F; // O
    localparam logic [7:0] PT_3 = 8'h44; // D
    localparam logic [7:0] PT_4 = 8'h45; // E

    // instanitate dut
    crack DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .key_valid(key_valid),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata)
    );

    // CT is external to crack so we give the DUT a real ct_mem so the bench behaves similar to our design
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
    // synthesized tb so we will use the proper post synthesis hierarchy paths
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

    // Task which will be used to load the ciphertext bytes directly into CT memory
    task load_test_ciphertext;
        begin
            write_ct(8'd0, CT_0);
            write_ct(8'd1, CT_1);
            write_ct(8'd2, CT_2);
            write_ct(8'd3, CT_3);
            write_ct(8'd4, CT_4);
        end
    endtask

    // task to check that the ciphertext memory actually contains our test vector
    task check_test_ciphertext_loaded;
        logic [7:0] data;
        begin
            read_ct(8'd0, data);
            assert(data == CT_0) else $error("ct[0] mismatch expected %02h got %02h", CT_0, data);

            read_ct(8'd1, data);
            assert(data == CT_1) else $error("ct[1] mismatch expected %02h got %02h", CT_1, data);

            read_ct(8'd2, data);
            assert(data == CT_2) else $error("ct[2] mismatch expected %02h got %02h", CT_2, data);

            read_ct(8'd3, data);
            assert(data == CT_3) else $error("ct[3] mismatch expected %02h got %02h", CT_3, data);

            read_ct(8'd4, data);
            assert(data == CT_4) else $error("ct[4] mismatch expected %02h got %02h", CT_4, data);
        end
    endtask

    // After crack succeeds the internal PT memory should contain the length prefixed plaintext "CODE"
    task check_plaintext_code;
        logic [7:0] data;
        begin
            read_pt(8'd0, data);
            assert(data == PT_0) else $error("pt[0] mismatch expected %02h got %02h", PT_0, data);

            read_pt(8'd1, data);
            assert(data == PT_1) else $error("pt[1] mismatch expected %02h got %02h", PT_1, data);

            read_pt(8'd2, data);
            assert(data == PT_2) else $error("pt[2] mismatch expected %02h got %02h", PT_2, data);

            read_pt(8'd3, data);
            assert(data == PT_3) else $error("pt[3] mismatch expected %02h got %02h", PT_3, data);

            read_pt(8'd4, data);
            assert(data == PT_4) else $error("pt[4] mismatch expected %02h got %02h", PT_4, data);
        end
    endtask

    // ============== Handshake helper tasks ==========
    
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

            // first make sure crack actually left the ready state w a buffer
            while (rdy !== 1'b0 && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal("crack never left ready after request");

            cycles = 0;

            // now wait until the search finishes w a generous buffer
            while (rdy !== 1'b1 && cycles < 10000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal("timeout waiting for crack to finish");
        end
    endtask

    // THE ACTUAL TESTS
    initial begin
        $display("=== TB: SYN crack ===");

        en = 1'b0;
        rst_n = 1'b0;

        // keep the reset low first so DUT starts from clean state then load the test ciphertext into CT memory
        #10;
        load_test_ciphertext();
        check_test_ciphertext_loaded();

        // with reset still low the DUT should be idle and ready
        @(posedge clk);
        #1;
        assert(rdy) else $error("Expected rdy=1 while crack is idle after reset");
        assert(!key_valid) else $error("Expected key_valid=0 before any request");

        // release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // crack should still be idle and ready before the request
        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!key_valid) else $error("Expected key_valid=0 before starting");
        assert(key == 24'h000000) else $error("Expected key output to be 0 before success");

        // start one brute-force search
        start_crack_once();

        // wait until crack finishes
        wait_for_crack_done();

        // Recall that the for this test vector the correct key is 24'h000001 so after the search finishes
        // key valid should be high and key should match expected key
        assert(key_valid) else $error("Expected key_valid=1 after successful crack");
        assert(key == EXPECTED_KEY) else $error("Expected key=%06h got %06h", EXPECTED_KEY, key);

        // the PT memory should now contain the decoded message "CODE"
        check_plaintext_code();

        // run the same search a second time this validates that crack can be reused again from its final ready state
        start_crack_once();
        wait_for_crack_done();

        assert(key_valid) else $error("Expected key_valid=1 after second run");
        assert(key == EXPECTED_KEY) else $error("Expected key=%06h on second run got %06h", EXPECTED_KEY, key);
        check_plaintext_code();

        $display("=== tb_syn_crack PASSED ===");
        $finish(0);
    end

endmodule : tb_syn_crack