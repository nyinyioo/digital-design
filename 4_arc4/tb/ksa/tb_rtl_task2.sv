`timescale 1ps/1ps

module tb_rtl_task2();

    // Top-level DUT signals
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

    // DUT instantiation
    task2 DUT(
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

    // Load the golden reference contents from a file in the same folder
    initial begin
        $readmemh("task2_golden.memh", golden);
    end

    // Read one memory location through the RTL hierarchy required by the handout
    task read_mem(input [7:0] mem_addr, output [7:0] mem_data);
        begin
            mem_data = DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[mem_addr];
        end
    endtask

    // Compare full S memory against the reference
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

    initial begin
        $display("=== TB: RTL task2 ===");

        // For task2 only the low 10 bits come from SW.
        // 24'h00033C fits in 10 bits so SW = 10'h33C is enough here.
        SW = 10'h33C;
        KEY = 4'hF;

        // Apply synchronous active-low reset on KEY[3]
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;
        @(posedge CLOCK_50);

        @(negedge CLOCK_50);
        KEY[3] = 1'b1;

        /*
            task2 should do this internally:
            1) run init
            2) run ksa

            We do not want the testbench to depend on exact internal timing,
            so we simply wait a very safe number of cycles and then check the
            final memory image.
        */
        repeat(1500) @(posedge CLOCK_50);

        check_against_golden();

        // Wait a little longer and check again.
        // This helps catch bugs where the top-level accidentally retriggers.
        repeat(20) @(posedge CLOCK_50);
        check_against_golden();

        // Reset a second time to make sure task2 reruns the full sequence correctly
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;
        @(posedge CLOCK_50);

        @(negedge CLOCK_50);
        KEY[3] = 1'b1;

        repeat(1500) @(posedge CLOCK_50);

        check_against_golden();

        $display("=== tb_rtl_task2 PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_task2