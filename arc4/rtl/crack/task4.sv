module task4(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    

    // Our top level task 4 module. We will instantiate the ciphertext memory, the crack, 
    // then start crack once after reset and show the result on the hex displays

    logic rst_n; // active low synchronous rst

    // assign rst to key 3
    assign rst_n = KEY[3]; 

    // crack handshake and result signals 
    logic crack_en; 
    logic crack_rdy; 
    logic crack_key_valid; 
    logic [23:0] crack_key; 

    // use a signal to be able to know when we've started crack and to not keep sending request each cycle
    logic started; 

    // ciphertext mem interface
    logic [7:0] ct_addr; 
    logic [7:0] ct_q; 

    // ledr not used 
    assign LEDR = 10'h000;

    // ======== Starting Crack w Pulse =======

    // we wait until crack is ready and then pulse en for one cycle similar to what we've been doing for t2,3
    always_ff @(posedge CLOCK_50) begin 

        // check if we need to rst signals 
        if (!rst_n) begin 
            crack_en <= 1'b0; 
            started <= 1'b0; 
        end else begin 
            // Set our default which is just no request 
            crack_en <= 1'b0; 

            // then once crack is ready and we haven't already started then we send one pulse 
            // after started will stay high so the search will keep running without being restarted over and over 
            if (!started && crack_rdy) begin 
                crack_en <= 1'b1; 
                started <= 1'b1; 
            end 
        end 
    end 


    // ======= HELPERS FOR HEX DISPLAY =======

    // Helper for when a valid key is found and we want to show it as a 6 hex digits across
    // hex5 to hex0. Each hex digit is 4 bits (1 nibble) and 24 bit key so 6 hex digits
    // this function will basically drive the hexoutput based on each nibble 
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

    // all segments off (will use this when the search is still running) since the readme says
    // displays should be blank while computing 
    function automatic logic [6:0] seg7_blank();
        begin
            seg7_blank = 7'h7F;
        end
    endfunction

    // if search finishes w no valid key board should show -------
    function automatic logic [6:0] seg7_dash();
        begin
            seg7_dash = 7'h3F;
        end
    endfunction

    // ====== DISPLAY LOGIC =======

    // we have a few cases. First if crack has not started yet we keep all displays blank 
    // if it has started but is still running we still keep all displays blank. If crack finished with a valid key
    // we show the key as 6 hex digits otherwise if no valid key was found show the dashes 
    always_comb begin

        // default 
        HEX0 = seg7_blank();
        HEX1 = seg7_blank();
        HEX2 = seg7_blank();
        HEX3 = seg7_blank();
        HEX4 = seg7_blank();
        HEX5 = seg7_blank();

        // if not started or search still in progress keep blank 
        if (!started || !crack_rdy) begin 
            HEX0 = seg7_blank();
            HEX1 = seg7_blank();
            HEX2 = seg7_blank();
            HEX3 = seg7_blank();
            HEX4 = seg7_blank();
            HEX5 = seg7_blank();
        end else if (crack_key_valid) begin 
            // crack is done w valid key display value 
            // crack_key[23:20] leftmost digit, crack_key[3:0] rightmost digit 
            HEX5 = seg7_hex(crack_key[23:20]);
            HEX4 = seg7_hex(crack_key[19:16]);
            HEX3 = seg7_hex(crack_key[15:12]);
            HEX2 = seg7_hex(crack_key[11:8]);
            HEX1 = seg7_hex(crack_key[7:4]);
            HEX0 = seg7_hex(crack_key[3:0]);
        end else begin 
            // no valid key was found show dashes 
            HEX0 = seg7_dash();
            HEX1 = seg7_dash();
            HEX2 = seg7_dash();
            HEX3 = seg7_dash();
            HEX4 = seg7_dash();
            HEX5 = seg7_dash();
        end 
    end 

    // Ciphertext memory. This mem is just being read during the burte force search. crack asks for ciphertext bytes by driving 
    // ct_addr and then ct_q returns the byte stored at that address 
    ct_mem ct(          
        .address(ct_addr),
        .clock(CLOCK_50),
        .data(8'd0),
        .wren(1'b0),
        .q(ct_q));

    // crack instance. Quick recall that crack tries keys one by one, decrypts CT checks whether the plain text is readable
    // and reports back if it found a valid key and what it is
    crack c(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(crack_en),
        .rdy(crack_rdy),
        .key_valid(crack_key_valid),
        .key(crack_key),
        .ct_addr(ct_addr),
        .ct_rddata(ct_q)
     );

endmodule: task4
