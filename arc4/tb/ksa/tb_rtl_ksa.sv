`timescale 1ps/1ps

module tb_rtl_ksa();

    // DUT signals
    logic clk;
    logic rst_n;
    logic en;
    logic rdy;
    logic [23:0] key;
    logic [7:0] addr;
    logic [7:0] rddata;
    logic [7:0] wrdata;
    logic wren;

    // This array holds the correct final S memory contents for key 24'h00033C.
    // We load it from a local memh file so the testbench stays readable.
    logic [7:0] golden [0:255];

    // state probes signals
    parameter IDLE = 2'd0, READ_I = 2'd1, READ_J = 2'd2, WRITE_I = 2'd3, WRITE_J = 2'd4; 
    logic [2:0] state, next_state;

    assign state       = DUT.state;
    assign next_state  = DUT.next_state;

    // datapath probes signals
    logic [7:0] i;
    logic [7:0] j;
    logic [7:0] j_new;
    logic [7:0] si;
     
    assign i     = DUT.i;
    assign j     = DUT.j;
    assign j_new = DUT.j_new;
    assign si    = DUT.si;


    // DUT instantiation
    ksa DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .key(key),
        .addr(addr),
        .rddata(rddata),
        .wrdata(wrdata),
        .wren(wren)
    );

    // Standalone S memory used by ksa
    s_mem s(
        .address(addr),
        .clock(clk),
        .data(wrdata),
        .wren(wren),
        .q(rddata)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Load the golden reference contents from a file in the same folder
    initial begin
        $readmemh("golden.memh", golden);
    end

    // Read one memory location through the RTL hierarchy
    task read_mem(input [7:0] mem_addr, output [7:0] mem_data);
        begin
            mem_data = s.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr];
        end
    endtask

    // Directly write one memory location through the RTL hierarchy
    // We use this only in the testbench to preload S with identity contents.
    task write_mem(input [7:0] mem_addr, input [7:0] mem_data);
        begin
            s.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr] = mem_data;
        end
    endtask

    // Load S = [0..255] directly into the memory.
    // The handout warns to do this after a short delay to avoid racing
    // the Altera memory model's own initialization.
    task load_identity_memory;
        integer i;
        begin
            for (i = 0; i < 256; i = i + 1) begin
                write_mem(i[7:0], i[7:0]);
            end
        end
    endtask

    // Compare the full S memory against the known-good final contents
    task check_against_golden;
        integer i;
        logic [7:0] mem_data;
        begin
            $display("Checking all 256 S memory entries against the golden reference...");
            for (i = 0; i < 256; i = i + 1) begin
                read_mem(i[7:0], mem_data);
                assert(mem_data == golden[i])
                    else $error("golden mismatch at s[%0d]: expected %02h got %02h", i, golden[i], mem_data);
            end
        end
    endtask

    // Wait until ksa finishes.
    // Since ksa uses ready/enable, after we pulse en it should go busy,
    // then eventually return to rdy = 1 when done.
    task wait_for_ksa_done;
        integer cycles;
        begin
            cycles = 0;

            // Wait until the module is actually busy
            while (rdy !== 1'b0 && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b0) else $fatal("ksa never left ready state after request");

            cycles = 0;

            // Now wait until it returns to ready
            while (rdy !== 1'b1 && cycles < 2000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            assert(rdy == 1'b1) else $fatal("timeout waiting for ksa to finish");
        end
    endtask

    // Send exactly one request pulse
    task start_ksa_once;
        begin
            @(negedge clk);
            en = 1'b1;
            @(posedge clk);
            #1;
            @(negedge clk);
            en = 1'b0;
        end
    endtask

    initial begin
        logic [7:0] mem_data;

        $display("=== TB: RTL KSA ===");

        // Default inputs
        en = 1'b0;
        key = 24'h00033C;
        rst_n = 1'b1;

        // Apply synchronous active-low reset
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        // While reset is active the module should be idle/ready
        assert(rdy) else $error("Expected rdy=1 during reset/idle");
        assert(!wren) else $error("Expected wren=0 during reset/idle");

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // Still idle and ready before any request
        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!wren) else $error("Expected wren=0 before request");

        // Wait a bit before directly touching the Altera memory model
        #10;
        load_identity_memory();

        // Quick sanity check that the preload worked
        read_mem(8'd0, mem_data);
        assert(mem_data == 8'h00) else $error("Expected s[0]=00 after identity preload");

        read_mem(8'd255, mem_data);
        assert(mem_data == 8'hff) else $error("Expected s[255]=ff after identity preload");

        // Start one KSA run and wait until it finishes
        start_ksa_once();
        wait_for_ksa_done();

        // Check the final S table
        check_against_golden();

        // Run a second time to make sure the module is reusable
        // after returning to ready.
        #10;
        load_identity_memory();

        start_ksa_once();
        wait_for_ksa_done();

        check_against_golden();

        $display("=== tb_rtl_ksa PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_ksa