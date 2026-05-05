`timescale 1ps/1ps

module tb_syn_arc4();

    // DUT signals
    logic clk;
    logic rst_n;
    logic en;
    logic rdy;
    logic [23:0] key;
    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;
    logic [7:0] pt_addr;
    logic [7:0] pt_rddata;
    logic [7:0] pt_wrdata;
    logic pt_wren;
    logic wren;

    // This array holds the correct plain text output bytes 
    // (key 24'h000018)
    logic [7:0] golden [0:255];

    // enable signals for submodules
    logic init_en, ksa_en, prga_en;

    // Module instantiations
    arc4 UUT (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(pt_addr),
        .pt_rddata(pt_rddata),
        .pt_wrdata(pt_wrdata),
        .pt_wren(pt_wren)
    );

    // Memory instantiations
    s_mem s(
        .address(s_addr),
        .clock(clk),
        .data(s_wrdata),
        .wren(s_wren),
        .q(s_rddata)
    );

    // cipher text 
    ct_mem ct(
        .address(ct_addr),
        .clock(clk),
        .data(8'd0),
        .wren(1'b0),
        .q(ct_rddata)
    );

    // plain text
    pt_mem pt(
        .address(pt_addr),
        .clock(clk),
        .data(pt_wrdata),
        .wren(pt_wren),
        .q(pt_rddata)
    );

    // Clock generation — 10ps period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Load golden reference
    initial begin
        $readmemh("test2_golden.memh", golden);
    end

    // memory taks
    task write_ct_mem(input [7:0] mem_addr, input [7:0] mem_data);
        \ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[mem_addr] = mem_data;
    endtask

    task read_pt_mem(input [7:0] mem_addr, output [7:0] mem_data);
        mem_data = \pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[mem_addr];
    endtask

       
    // load cipher_text array
    // stored in test2.memh
    task load_ct_memory;
        integer idx;
        logic [7:0] ct_data [0:255];
        begin
            $readmemh("test2.memh", ct_data);
            for (idx = 0; idx < 256; idx = idx + 1)
                write_ct_mem(idx[7:0], ct_data[idx]);
        end
    endtask

    // Check PT against golden
    // gold
    task check_against_golden;
        integer i;
        logic [7:0] mem_data;
        begin
            $display("Checking PT memory against golden reference...");
            for (i = 0; i <= golden[0]; i = i + 1) begin
                read_pt_mem(i[7:0], mem_data);
                assert(mem_data == golden[i])
                    else $error("mismatch at pt[%0d]: expected %02h got %02h", i, golden[i], mem_data);
            end
        end
    endtask

    // Wait for PRGA to finish
    task wait_for_arc4_done;
        integer cycles;
        begin
            cycles = 0;
            while (rdy !== 1'b0 && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal(1, "arc4 never left ready state");

            cycles = 0;
            while (rdy !== 1'b1 && cycles < 100000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal(1, "timeout waiting for arc4 to finish");
        end
    endtask

    // Pulse en once
    task start_arc4_once;
        begin
            @(negedge clk);
            en = 1'b1;
            @(posedge clk);
            #1;
            @(negedge clk);
            en = 1'b0;
        end
    endtask


    // Stimulus
    initial begin
        $display("=== TB: SYN ARC4 ===");

        // default values
        init_en = 1'b0;
        ksa_en = 1'b0;
        prga_en = 1'b0;
        key = 24'h000018;  // test2 simulation key
        rst_n = 1'b1;

        // Apply synchronous active-low reset
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        // While reset is active the module should be idle/ready
        assert(rdy) else $error("Expected rdy=1 during reset/idle");
        assert(!pt_wren) else $error("Expected wren=0 during reset/idle");


        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // Still idle and ready before any request
        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!pt_wren) else $error("Expected wren=0 before request");

        #10;
        load_ct_memory();

        // run arc4
        key = 24'h000018;
        en = 1'b0;
        start_arc4_once();
        wait_for_arc4_done();

        // check PT
        check_against_golden();

        // run second time 
        #10;
        load_ct_memory();
        start_arc4_once();
        wait_for_arc4_done();
        check_against_golden();

        $display("=== tb_syn_arc4 PASSED ===");

        $finish(0);
    end

endmodule: tb_syn_arc4