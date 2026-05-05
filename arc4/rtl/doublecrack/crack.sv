module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
             // extra ports added for our task 5:
             input logic [23:0] start_key, // this lets us choose where this crack core begins searching 
             input logic [23:0] key_step,  // this lets us choose how much to increment by after a failed key 
             input logic [7:0] pt_rd_addr, // this lets doublecrack read back this cores internal PT memory (we set addr and then pt_rddata will be the actual content)
             output logic [7:0] pt_rddata
            );


    // This file contains our code for the crack module
    // The overall plan is to try a candidate key, run arc4 using that candidate key, then arc4 will
    // decrypt the ciphertext into our internal plaintext memory. After arc4 finishes, then we will read the
    // plaintext back and check if all characters are printable ASCII. If valid we report success and stop else
    // we increment the key and try again

    // Notes from readme
    // CT is external to crack
    // PT is internal to crack
    // S is also internal through the internal arc4 instance
    // For task 5 we now want the same crack logic, but we allow the caller to choose:
    // - what key to start from
    // - what step size to increment by

    // Internal signals
    // current key we are testing
    logic [23:0] candidate_key;

    // once we find a good key we must store it
    logic [23:0] found_key;

    // keeps track of whether the final result was success or failure
    logic success_found;

    // length of the decrypted message from pt[0]
    // pt[0] has the length then from 1 till length are the actual characters
    logic [7:0] message_length;

    // current plaintext index we are checking
    logic [7:0] check_index;

    // Internal PT memory interface
    logic [7:0] pt_addr;
    logic [7:0] pt_wrdata;
    logic pt_wren;
    logic [7:0] pt_q;

    // arc4 interface
    logic a4_en;
    logic a4_rdy;
    logic [7:0] a4_ct_addr;
    logic [7:0] a4_pt_addr;
    logic [7:0] a4_pt_wrdata;
    logic a4_pt_wren;

    // Bool to check for printable ASCII as per the readme
    // all decrypted characters need to be between 8'h20 and 8'h7E
    logic ascii_ok;
    assign ascii_ok = (pt_q >= 8'h20 && pt_q <= 8'h7E);

    // helper to know if there are no more keys left for this crack core 
    // note this will work for both step = 1 and step = 2 
    // if step = 1 then the final key is FFFFFF
    // if step = 2 and we started at 0 then the final key is FFFFFF
    // if step = 2 and we started at 1 then the final key is FFFFFF
    logic last_candidate; 
    assign last_candidate = (candidate_key > (24'hFFFFFF - key_step)); 

    // States (same as before)
    typedef enum logic [2:0] {
        IDLE,
        START_ARC4,
        WAIT_ARC4,
        CHECK_LEN,
        CHECK_CHAR,
        DONE
    } state_t;

    state_t state;
    state_t next_state;

    // comb next state logic
    always_comb begin
        case (state)

            // ready and just waiting for a new request
            IDLE: begin
                if (en) begin
                    next_state = START_ARC4;
                end else begin
                    next_state = IDLE;
                end
            end

            // We pulse en to arc4 when arc4 is ready
            // Then on the next cycle we move into WAIT_ARC4 and let it work
            START_ARC4: begin
                if (a4_rdy) begin
                    next_state = WAIT_ARC4;
                end else begin
                    next_state = START_ARC4;
                end
            end

            // wait until arc4 finishes decrypting for this candidate key
            WAIT_ARC4: begin
                if (a4_rdy) begin
                    next_state = CHECK_LEN;
                end else begin
                    next_state = WAIT_ARC4;
                end
            end

            // After decryption is complete, pt[0] holds the message length
            // if the length is 0 then there are no characters to check
            CHECK_LEN: begin
                if (pt_q == 8'd0) begin
                    next_state = DONE;
                end else begin
                    next_state = CHECK_CHAR;
                end
            end

            // In CHECK_CHAR we read one plaintext byte at a time
            CHECK_CHAR: begin

                // check if the character is not printable ASCII
                if (!ascii_ok) begin
                    // if this was the last possible key for this core then we are done with failure
                    // otherwise increment by key_step and try again
                    if (last_candidate) begin
                        next_state = DONE;
                    end else begin
                        next_state = START_ARC4;
                    end
                end else begin
                    // if the character is printable check if this was the last character
                    // if so then we are done with success otherwise keep checking
                    if (check_index == message_length) begin
                        next_state = DONE;
                    end else begin
                        next_state = CHECK_CHAR;
                    end
                end
            end

            // if a new request comes in while we are done restart the full search
            DONE: begin
                if (en) begin
                    next_state = START_ARC4;
                end else begin
                    next_state = DONE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // sequential logic for state and dp regs
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            candidate_key <= 24'd0;
            found_key <= 24'd0;
            success_found <= 1'b0;
            message_length <= 8'd0;
            check_index <= 8'd1;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    // when a new request is accepted start the search fresh
                    // for task 5 the start point now comes from start_key
                    if (en) begin
                        candidate_key <= start_key;
                        found_key <= 24'd0;
                        success_found <= 1'b0;
                        message_length <= 8'd0;
                        check_index <= 8'd1;
                    end
                end

                START_ARC4: begin
                    // nothing needed here
                    // the state is here so the combinational logic can generate a one cycle start pulse into arc4
                end

                WAIT_ARC4: begin
                    // arc4 owns PT while it is decrypting
                    // crack will just wait until the current candidate_key has finished producing a plaintext into PT
                end

                CHECK_LEN: begin
                    // pt_addr is 0 in this state so pt_q is the length byte
                    // we save the length so we know how many characters need to be checked
                    message_length <= pt_q;

                    // reset the character index so if we continue to CHECK_CHAR the first character examined is pt[1]
                    check_index <= 8'd1;

                    // if the length is 0 then there are no chars to check and this candidate key is a success
                    if (pt_q == 8'd0) begin
                        found_key <= candidate_key;
                        success_found <= 1'b1;
                    end
                end

                CHECK_CHAR: begin
                    if (!ascii_ok) begin
                        // current pt char is not printable so this candidate key is rejected
                        if (last_candidate) begin
                            // if this was the final key for this crack core then the search ends with failure
                            found_key <= 24'd0;
                            success_found <= 1'b0;
                        end else begin
                            // otherwise move to the next key for this core
                            // in task 5 this increment is key_step instead of always being 1
                            candidate_key <= candidate_key + key_step;
                            message_length <= 8'd0;
                            check_index <= 8'd1;
                            success_found <= 1'b0;
                        end
                    end else begin
                        // current pt character is printable
                        // if this was the final character then we found a valid key
                        // else move on to the next character
                        if (check_index == message_length) begin
                            found_key <= candidate_key;
                            success_found <= 1'b1;
                        end else begin
                            check_index <= check_index + 8'd1;
                        end
                    end
                end

                DONE: begin
                    // DONE is also a ready state
                    // if another request arrives restart this crack core from start_key
                    if (en) begin
                        candidate_key <= start_key;
                        found_key <= 24'd0;
                        success_found <= 1'b0;
                        message_length <= 8'd0;
                        check_index <= 8'd1;
                    end
                end

                default: begin
                    // good practice but nothing needed
                end
            endcase
        end
    end

    // ARC4 start pulse
    // each cycle en is high counts as a distinct req so a4_en must only be pulsed for one cycle
    // and only when arc4 is ready
    always_comb begin
        a4_en = 1'b0;
        if (state == START_ARC4 && a4_rdy) begin
            a4_en = 1'b1;
        end
    end

    // PT memory port mux 
    // PT has only one port so either arc4 uses it or crack uses it 
    // while arc4 is running; arc4 writes decrypted plaintext into PT
    // while crack is chekcing: crack reads pt[0] in CHECK_LEN and pt[check_index] in CHECK_CHAR
    // while in IDLE or DONE; the parent can read PT through pt_rd_addr 
    always_comb begin 
        pt_addr = 8'd0; 
        pt_wrdata = 8'd0; 
        pt_wren = 1'b0;

        case (state) 
            // during decryption arc4 controls the pt memory since it is producing the plaintext
            START_ARC4, WAIT_ARC4: begin 
                pt_addr = a4_pt_addr; 
                pt_wrdata = a4_pt_wrdata; 
                pt_wren = a4_pt_wren; 
            end 

            // in CHECK_LEN we want pt_q to reflect pt[0] because that byte stores the message length 
            CHECK_LEN: begin 
                pt_addr = 8'd0;
                pt_wrdata = 8'd0; 
                pt_wren = 1'b0; 
            end 

            // in CHECK_CHAR we want pt_q to reflect the current plaintext character being validated 
            CHECK_CHAR: begin 
                pt_addr = check_index; 
                pt_wrdata = 8'd0; 
                pt_wren = 1'b0; 
            end 

            // when not busy the parent can inspect the PT memory using the added task 5 ports 
            default: begin 
                pt_addr = pt_rd_addr; 
                pt_wrdata = 8'd0; 
                pt_wren = 1'b0; 
            end 
        endcase
    end 

    // Main outputs 

    // crack is ready only when it can accpet a new req immediately which is in idle and done 
    assign rdy = (state == IDLE || state == DONE); 

    // key valid only goes high if the search finished and the result was success
    assign key_valid = (state == DONE && success_found); 

    // report the discovered key 
    assign key = found_key; 

    // CT is external to crack 
    // arc4 is the only block that ctually reads ciphertext so crack simply forwards arc4's CT address
    assign ct_addr = a4_ct_addr;

    // expose PT read data for doublecrack so it can copy the winning plaintext into the shared PT memory 
    assign pt_rddata = pt_q; 


    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(
        .address(pt_addr),
        .clock(clk),
        .data(pt_wrdata),
        .wren(pt_wren),
        .q(pt_q)
    );

    arc4 a4(
        .clk(clk),
        .rst_n(rst_n),
        .en(a4_en),
        .rdy(a4_rdy),
        .key(candidate_key),
        .ct_addr(a4_ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(a4_pt_addr),
        .pt_wrdata(a4_pt_wrdata),
        .pt_rddata(pt_q),
        .pt_wren(a4_pt_wren)
    );

endmodule : crack