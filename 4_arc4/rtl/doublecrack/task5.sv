`timescale 1ps/1ps

module task5(
    input logic CLOCK_50,
    input logic [3:0] KEY,
    input logic [9:0] SW,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5,
    output logic [9:0] LEDR
);

    // Our top level task 5 module
    // This is very similar to task4 except now instead of using one crack core
    // we will use doublecrack which itself has two crack cores running in parallel
    // - after reset start the search once
    // - keep HEX displays blank while computing
    // - if a valid key is found display the 24 bit key as 6 hex digits
    // - if no valid key is found display dashes

    // active low synchronous reset
    logic rst_n;

    // assign reset to KEY[3]
    assign rst_n = KEY[3];

    // doublecrack handshake and result signals
    logic dc_en;
    logic dc_rdy;
    logic dc_key_valid;
    logic [23:0] dc_key;

    // use this to remember whether we already launched doublecrack
    // so we do not keep pulsing the enable every cycle
    logic started;

    // ciphertext memory interface
    logic [7:0] ct_addr;
    logic [7:0] ct_q;


    // ======== Starting doublecrack with one pulse ========
    // The ready enable protocol is the same as before
    // we wait until doublecrack is ready and then pulse dc_en for one cycle
    // after that started stays high so we do not restart the search again
    always_ff @(posedge CLOCK_50) begin
        if (!rst_n) begin
            dc_en <= 1'b0;
            started <= 1'b0;
        end else begin
            // default is no request
            dc_en <= 1'b0;

            // once doublecrack is ready and we have not already started
            // send exactly one pulse
            if (!started && dc_rdy) begin
                dc_en <= 1'b1;
                started <= 1'b1;
            end
        end
    end

    // ======== HELPERS FOR HEX DISPLAY ========
    // helper for when a valid key is found and we want to show it as 6 hex digits
    // hex5 to hex0
    // each hex digit is 4 bits so a 24 bit key gives us 6 hex digits
    function automatic logic [6:0] seg7_hex(input logic [3:0] nibble);
        begin
            case (nibble)
                4'h0: seg7_hex = 7'h40;
                4'h1: seg7_hex = 7'h79;
                4'h2: seg7_hex = 7'h24;
                4'h3: seg7_hex = 7'h30;
                4'h4: seg7_hex = 7'h19;
                4'h5: seg7_hex = 7'h12;
                4'h6: seg7_hex = 7'h02;
                4'h7: seg7_hex = 7'h78;
                4'h8: seg7_hex = 7'h00;
                4'h9: seg7_hex = 7'h10;
                4'hA: seg7_hex = 7'h08;
                4'hB: seg7_hex = 7'h03;
                4'hC: seg7_hex = 7'h46;
                4'hD: seg7_hex = 7'h21;
                4'hE: seg7_hex = 7'h06;
                4'hF: seg7_hex = 7'h0E;
                default: seg7_hex = 7'h7F;
            endcase
        end
    endfunction

    // all segments off
    // we use this when the search is still running since the displays should stay blank while computing
    function automatic logic [6:0] seg7_blank();
        begin
            seg7_blank = 7'h7F;
        end
    endfunction

    // if the search finishes with no valid key found then the board should show ------
    function automatic logic [6:0] seg7_dash();
        begin
            seg7_dash = 7'h3F;
        end
    endfunction

    // ======== DISPLAY LOGIC ========
    // same display behavior as task4
    // if the search has not started yet keep blank
    // if the search is still running keep blank
    // if the search is done with a valid key show the key
    // if the search is done with no valid key show dashes
    always_comb begin
        // defaults
        HEX0 = seg7_blank();
        HEX1 = seg7_blank();
        HEX2 = seg7_blank();
        HEX3 = seg7_blank();
        HEX4 = seg7_blank();
        HEX5 = seg7_blank();

        // if not started or still searching keep everything blank
        if (!started || !dc_rdy) begin
            HEX0 = seg7_blank();
            HEX1 = seg7_blank();
            HEX2 = seg7_blank();
            HEX3 = seg7_blank();
            HEX4 = seg7_blank();
            HEX5 = seg7_blank();
        end else if (dc_key_valid) begin
            // doublecrack finished with a valid key
            // crack_key[23:20] is the leftmost hex digit
            // crack_key[3:0] is the rightmost digit
            HEX5 = seg7_hex(dc_key[23:20]);
            HEX4 = seg7_hex(dc_key[19:16]);
            HEX3 = seg7_hex(dc_key[15:12]);
            HEX2 = seg7_hex(dc_key[11:8]);
            HEX1 = seg7_hex(dc_key[7:4]);
            HEX0 = seg7_hex(dc_key[3:0]);
        end else begin
            // finished with no valid key found
            HEX0 = seg7_dash();
            HEX1 = seg7_dash();
            HEX2 = seg7_dash();
            HEX3 = seg7_dash();
            HEX4 = seg7_dash();
            HEX5 = seg7_dash();
        end
    end

    // Ciphertext memory
    // This is the same idea as task4
    // CT is external to doublecrack and doublecrack asks for bytes by driving ct_addr
    // then ct_q returns the byte stored at that address
    // keep this instance name exactly as ct
    ct_mem ct(
        .address(ct_addr),
        .clock(CLOCK_50),
        .data(8'd0),
        .wren(1'b0),
        .q(ct_q)
    );

    // doublecrack instance
    // this does the actual task 5 work
    // it runs two crack cores in parallel internally
    // keep this instance name exactly as dc since the task5 hierarchy depends on it
    doublecrack dc(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(dc_en),
        .rdy(dc_rdy),
        .key(dc_key),
        .key_valid(dc_key_valid),
        .ct_addr(ct_addr),
        .ct_rddata(ct_q)
    );

endmodule : task5