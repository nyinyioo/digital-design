`timescale 1ps/1ps

module tb_rtl_init();

    // DUT signals
    logic clk;
    logic rst_n;
    logic en;
    logic rdy;
    logic [7:0] addr;
    logic [7:0] wrdata;
    logic wren;

    // DUT instantiation
    init DUT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .rdy(rdy),
        .addr(addr),
        .wrdata(wrdata),
        .wren(wren)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Helper task:
    // While init is busy, it should be writing s[i] = i.
    // So addr and wrdata should always match the expected counter value.
    task check_write_cycle(input [7:0] expected_value);
        begin
            assert(!rdy) else $error("Expected rdy=0 while busy");
            assert(wren) else $error("Expected wren=1 while writing");
            assert(addr == expected_value) else $error("Expected addr=%0d, got %0d", expected_value, addr);
            assert(wrdata == expected_value) else $error("Expected wrdata=%0d, got %0d", expected_value, wrdata);
        end
    endtask

    initial begin
        $display("=== RTL INIT TESTEBENCH ===");

        // Default inputs
        en = 1'b0;
        rst_n = 1'b1;

        // Apply synchronous active-low reset
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        // While reset is active, the module should be idle/ready
        assert(rdy) else $error("Expected rdy=1 during reset/idle");
        assert(!wren) else $error("Expected wren=0 during reset/idle");
        assert(addr == 8'd0) else $error("Expected addr=0 after reset");
        assert(wrdata == 8'd0) else $error("Expected wrdata=0 after reset");

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // Still idle and ready for a request
        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!wren) else $error("Expected wren=0 after reset release");

        // Send exactly one enable pulse
        // This should start a single initialization request.
        @(negedge clk);
        en = 1'b1;
        @(posedge clk);
        #1;

        // First write cycle should target entry 0
        check_write_cycle(8'd0);

        // Deassert en immediately on the next cycle since one en cycle = one request in the microprotocol
        @(negedge clk);
        en = 1'b0;

        // Next write cycle should target entry 1
        @(posedge clk);
        #1;
        check_write_cycle(8'd1);

        // Wait long enough for the full 0..255 write sequence to finish, we will give it long enough time w a buffer
        repeat(260) @(posedge clk);
        #1;

        // After completion, the module should be back in ready/idle state.
        assert(rdy) else $error("Expected rdy=1 after init completes");
        assert(!wren) else $error("Expected wren=0 after init completes");

        // Start a second request to make sure the module is reusable and correctly restarts from address 0.
        @(negedge clk);
        en = 1'b1;
        @(posedge clk);
        #1;
        check_write_cycle(8'd0);

        @(negedge clk);
        en = 1'b0;

        @(posedge clk);
        #1;
        check_write_cycle(8'd1);

        $display("=== tb_rtl_init PASSED ===");
        $finish(0);
    end

endmodule : tb_rtl_init