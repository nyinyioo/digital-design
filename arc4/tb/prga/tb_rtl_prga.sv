`timescale 1ps/1ps
module tb_rtl_prga();

    // DUT signals
    logic clk;
    logic rst_n;
    logic en;
    logic rdy;
    logic [23:0] key;
    logic [7:0] s_addr;
    logic [7:0] s_rddata;
    logic [7:0] s_wrdata;
    logic s_wren;
    logic [7:0] ct_addr;
    logic [7:0] ct_rddata;
    logic [7:0] pt_addr;
    logic [7:0] pt_rddata;
    logic [7:0] pt_wrdata;
    logic [7:0] msg_length;
    logic pt_wren;
    integer idx;
    logic [7:0] mem_data;

    // This array holds the correct plain text output bytes 
    // (key 24'h000018)
    logic [7:0] golden [0:255];

    // State probes
    logic [3:0] state, next_state;
    assign state      = DUT.state;
    assign next_state = DUT.next_state;

    // Datapath probes
    logic [7:0] i, j, j_new, si, sj, k, msg_len;
    assign i = DUT.i;
    assign j = DUT.j;
    assign j_new = DUT.j_new;
    assign si = DUT.si;
    assign sj = DUT.sj;
    assign k = DUT.k;
    assign msg_len = DUT.msg_len;

    // DUT instantiation
    prga DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .s_addr(s_addr),
        .s_rddata(s_rddata),
        .s_wrdata(s_wrdata),
        .s_wren(s_wren),
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

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Load golden reference
    initial begin
        $readmemh("test2_golden.memh", golden);
    end

    // memory tasks
    task read_s_mem(input [7:0] mem_addr, output [7:0] mem_data);
        mem_data = s.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr];
    endtask

    task write_s_mem(input [7:0] mem_addr, input [7:0] mem_data);
        s.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr] = mem_data;
    endtask

    task read_ct_mem(input [7:0] mem_addr, output [7:0] mem_data);
        mem_data = ct.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr];
    endtask

    task write_ct_mem(input [7:0] mem_addr, input [7:0] mem_data);
        ct.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr] = mem_data;
    endtask

    task read_pt_mem(input [7:0] mem_addr, output [7:0] mem_data);
        mem_data = pt.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr];
    endtask


    // load S array (post-ksa), not identity
    // for key test2 key: 24'h000018
    task load_s_memory;
        integer idx;
        logic [7:0] s_data [0:255];
        begin
            $readmemh("test2_s_golden.memh", s_data);
            for (idx = 0; idx < 256; idx = idx + 1)
                write_s_mem(idx[7:0], s_data[idx]);
        end
    endtask

       
    // load cipher_text array
    // stored in test2.memh
    task load_ct_memory;
        integer idx;
        logic [7:0] ct_data [0:255];
        begin
            // load test2 ciphertext matching key 0x000018
            $readmemh("test2.memh", ct_data);
            for (idx = 0; idx < 256; idx = idx + 1)
                write_ct_mem(idx[7:0], ct_data[idx]);
        end
    endtask

    // Check PT against golden
    // golden = test2_golden.memh
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
    task wait_for_prga_done;
        integer cycles;
        begin
            cycles = 0;
            while (rdy !== 1'b0 && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal("prga never left ready state");

            cycles = 0;
            while (rdy !== 1'b1 && cycles < 2000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal("timeout waiting for prga to finish");
        end
    endtask

    // Pulse en once
    task start_prga_once;
        begin
            @(negedge clk);
            en = 1'b1;
            @(posedge clk);
            #1;
            @(negedge clk);
            en = 1'b0;
        end
    endtask


    //  stimulus
    initial begin
        $display("=== TB: RTL PRGA ===");

        // Default inputs
        en = 1'b0;
        key = 24'h000018;  // test2 simulation key
        rst_n = 1'b1;

        // Apply synchronous active-low reset
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        // While reset is active the module should be idle/ready
        assert(rdy)   else $error("Expected rdy=1 during reset");
        assert(!pt_wren) else $error("Expected pt_wren=0 during reset");

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // Still idle and ready before any request
        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!s_wren) else $error("Expected s_wren=0 before request");

        // Preload memories
        #10;
        load_s_memory();  // S is not identity in PRGA (post KSA array)
        load_ct_memory();

        // start PRGA and wait for finish
        start_prga_once();
        wait_for_prga_done();

        // Check results
        check_against_golden();

        // Run a second time 
         #10;
        load_s_memory();
        load_ct_memory();

        // $display("key 0x000018\n");
        // check memory contents after load_s_memory()
        // this is the memory stored in test2_s_golden.memh
        read_s_mem(8'd0, mem_data);
        $display("s[0] after load = %02h", mem_data);
        read_s_mem(8'd1, mem_data);
        $display("s[1] after load = %02h", mem_data);
        read_s_mem(8'd16, mem_data); 
        $display("s[16] first load = %02h", mem_data);

        // start PRGA and wait for finish
        start_prga_once();
        wait_for_prga_done();

        // check PT memory contents after PRGA
        // PRGA uses scrambled_s to generate pad
        // plain_text[k] = pad ^ cipher_text[k]
        read_pt_mem(8'd0, msg_length);
        $display("pt[0] = %02h (message length = %0d)", msg_length, msg_length);
        for (idx = 1; idx <= msg_length; idx = idx + 1) begin
            read_pt_mem(idx[7:0], mem_data);
            $display("pt[%0d] = %02h = '%c'", idx, mem_data, mem_data);
        end

        // check againt golden
        // test2_golden.memh contains correct plain text bytes 
        check_against_golden();

        $display("=== tb_rtl_prga PASSED ===");
        $finish(0);
    end

endmodule: tb_rtl_prga