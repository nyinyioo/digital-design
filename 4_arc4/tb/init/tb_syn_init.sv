`timescale 1ps/1ps

module tb_syn_init();

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

    // Same helper as RTL testbench.
    // But note that this testbench does not depend on internal state names,
    // so it is much safer for synthesized/netlist simulation.
    task check_write_cycle(input [7:0] expected_value);
        begin
            assert(!rdy) else $error("Expected rdy=0 while busy");
            assert(wren) else $error("Expected wren=1 while writing");
            assert(addr == expected_value) else $error("Expected addr=%0d, got %0d", expected_value, addr);
            assert(wrdata == expected_value) else $error("Expected wrdata=%0d, got %0d", expected_value, wrdata);
        end
    endtask

    initial begin
        $display("=== TB: SYN init ===");

        // Default inputs
        en = 1'b0;
        rst_n = 1'b1;

        // Apply synchronous active-low reset
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        #1;

        assert(rdy) else $error("Expected rdy=1 during reset/idle");
        assert(!wren) else $error("Expected wren=0 during reset/idle");
        assert(addr == 8'd0) else $error("Expected addr=0 after reset");
        assert(wrdata == 8'd0) else $error("Expected wrdata=0 after reset");

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        assert(rdy) else $error("Expected rdy=1 after reset release");
        assert(!wren) else $error("Expected wren=0 after reset release");

        // One-cycle request pulse
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

        // Wait until the full initialization has definitely completed
        repeat(260) @(posedge clk);
        #1;

        assert(rdy) else $error("Expected rdy=1 after init completes");
        assert(!wren) else $error("Expected wren=0 after init completes");

        // Verify the module can accept a second request
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

        $display("=== tb_syn_init PASSED ===");
        $finish(0);
    end

endmodule : tb_syn_init