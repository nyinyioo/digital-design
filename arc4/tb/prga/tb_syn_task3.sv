`timescale 1ps/1ps
module tb_syn_task3();

    // top-level DUT signals
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [6:0] HEX0;
    logic [6:0] HEX1;
    logic [6:0] HEX2;
    logic [6:0] HEX3;
    logic [6:0] HEX4;
    logic [6:0] HEX5;
    logic [9:0] LEDR;

    // Golden reference memory contents for key 24'h00033C
    logic [7:0] golden [0:255];

    // task3 DUT instantiation
    task3 DUT(
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

    // clock generation
    initial begin
        CLOCK_50 = 1'b0;
        forever #5 CLOCK_50 = ~CLOCK_50;
    end

    // Load golden reference
    initial begin
        $readmemh("test2_golden.memh", golden);
    end

    // read PT memory
    task read_pt_mem(input [7:0] mem_addr, output [7:0] mem_data);
        mem_data = DUT.\pt|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[mem_addr];
    endtask

    // load cipher_text array
    // stored in test2.memh
    task load_ct_mem;
        integer i;
        logic [7:0] ct_data [0:255];
        begin
            $readmemh("test2.memh", ct_data);
            #10;
            for (i = 0; i < 256; i = i + 1)
                DUT.\ct|altsyncram_component|auto_generated|altsyncram1|ram_block3a0 .ram_core0.ram_core0.mem[i] = ct_data[i];
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

    // stimulus
   initial begin
        $display("=== TB: SYN task3 ===");
        
        // Set key and ciphertext inputs
        SW = 10'h018;
        KEY = 4'hF;

        // load cipher_text array
        load_ct_mem();

        // Apply synchronous active-low reset on KEY[3]
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;
        @(posedge CLOCK_50);
        @(negedge CLOCK_50);
        KEY[3] = 1'b1;

        repeat(5) @(posedge CLOCK_50);

        // wait for arc4 to finish
        repeat(5000) @(posedge CLOCK_50);

        // check PT against golden 
        check_against_golden();

        // Reset a second time 
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;
        @(posedge CLOCK_50);
        @(negedge CLOCK_50);
        KEY[3] = 1'b1;

        repeat(5) @(posedge CLOCK_50);

        // wait for arc4 to finish
        repeat(5000) @(posedge CLOCK_50);

        // check PT against golden 
        check_against_golden();

        $display("=== tb_syn_task3 PASSED ===");
        $finish(0);
    end

endmodule: tb_syn_task3
