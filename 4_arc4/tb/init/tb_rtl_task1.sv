`timescale 1ps/1ps

module tb_rtl_task1();

    // Top-level DUT signals
    logic CLOCK_50;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [9:0] LEDR;

    // DUT instantiation
    task1 DUT(
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

    // Read the RTL memory contents directly through the hierarchy required by the lab readme
    logic [7:0] mem_data;

    task read_mem(input [7:0] addr, output [7:0] data);
        begin
            data = DUT.s.altsyncram_component.m_default.altsyncram_inst.mem_data[addr];
        end
    endtask

    

    // Check all 256 locations and verify s[i] = i.
    task check_full_memory_image;
        integer i;
        begin
            $display("Checking all 256 memory locations:");
            for (i = 0; i < 256; i = i + 1) begin
                read_mem(i[7:0], mem_data);
                assert(mem_data == i[7:0])
                    else $error("s[%0d] expected %0d, got %0d", i, i, mem_data);
            end
        end
    endtask

    initial begin
        $display("===== RTL TASK1 TESTBENCH ======");

        // Default inputs
        SW = 10'd0;
        KEY = 4'hF;

        // Apply synchronous active-low reset on KEY[3]
        @(negedge CLOCK_50);
        KEY[3] = 1'b0;
        @(posedge CLOCK_50);

        @(negedge CLOCK_50);
        KEY[3] = 1'b1;

        // Wait long enough for:
        // - reset release
        // - one-cycle start pulse generated inside task1
        // - all 256 writes to complete
        repeat(270) @(posedge CLOCK_50);

        // After task1 finishes, the memory should contain 0..255
        check_full_memory_image();

        // Now we wait extra cycles and will make sure the contents do not change. This basically
        // verifys that task1 only activates init once after reset and does not keep writing forever
        repeat(20) @(posedge CLOCK_50);
        check_full_memory_image();

        $display("=== tb_rtl_task1 PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_task1