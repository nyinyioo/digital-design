module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);

    // in this module we want to run two crack cores in parallel where
    // one will search 0, 2, 4, .. and the other is searching
    // 1, 3, 5 ....
    //
    // since doublecrack only gets one external CT port from the top level
    // we first copy the ciphertext into two private ct memories
    // then let each crack core read from its own private ct memory
    // once one crack core succeeds, we copy that core's PT memory into the shared PT memory
    //
    // this version is a bit more careful with memory timing
    // instead of assuming ct_rddata or winner_pt_data are usable immediately
    // we split those actions into:
    // - set address
    // - then capture / write on the next state

    // Useful search signals
    logic [23:0] found_key;
    logic success_found;

    // need a signal to figure out which crack core won
    logic winner_is_c1;

    // length of the message copied from external CT
    logic [7:0] ct_length;

    // used while copying external CT into the two private ct memories
    logic [7:0] ct_copy_index;

    // used while copying the winning PT into the shared PT memory
    logic [7:0] pt_copy_index;
    logic [7:0] pt_copy_length;

    // Shared PT Memory Interface
    logic [7:0] pt_addr;
    logic [7:0] pt_wrdata;
    logic pt_wren;

    // CT memories for the two crack cores
    logic [7:0] ct1_addr;
    logic [7:0] ct1_wrdata;
    logic ct1_wren;
    logic [7:0] ct1_q;

    logic [7:0] ct2_addr;
    logic [7:0] ct2_wrdata;
    logic ct2_wren;
    logic [7:0] ct2_q;

    // c1 signals
    logic c1_en;
    logic c1_rdy;
    logic [23:0] c1_key;
    logic c1_key_valid;
    logic [7:0] c1_ct_addr;
    logic [7:0] c1_pt_rd_addr;
    logic [7:0] c1_pt_rddata;

    // c2 signals
    logic c2_en;
    logic c2_rdy;
    logic [23:0] c2_key;
    logic c2_key_valid;
    logic [7:0] c2_ct_addr;
    logic [7:0] c2_pt_rd_addr;
    logic [7:0] c2_pt_rddata;

    // helper so the shared PT copy logic can just look at one signal
    logic [7:0] winner_pt_data;
    assign winner_pt_data = winner_is_c1 ? c1_pt_rddata : c2_pt_rddata;

    // States
    typedef enum logic [3:0] {
        IDLE, // waiting for a req

        // first read ct[0] to get the length
        SET_LEN_ADDR, // set external ct_addr = 0
        CAPTURE_LEN, // ct_rddata now holds ct[0], store it and copy into ct1[0] and ct2[0]

        // then copy ct[1] through ct[length]
        SET_CT_ADDR, // set external ct_addr = ct_copy_index
        COPY_CT_BYTE, // ct_rddata now valid for that index, copy into ct1 and ct2

        // launch the two crack cores
        START_CORES, // pulse en once into both crack cores
        WAIT_FOR_BUSY, // wait until both crack cores have actually left ready and begin cracking
        WAIT_FOR_CORES, // wait for either core to succeed or both to finish w failure

        // once one wins, copy that core's PT into shared dc.pt
        SET_PT_ADDR, // drive pt_copy_index into the winning core readback port
        COPY_PT_BYTE, // winner_pt_data now valid, write that byte into shared PT

        DONE
    } state_t;

    state_t state, next_state;

    // combinational next state logic
    always_comb begin
        case (state)

            // waiting for a new request
            IDLE: begin
                if (en) begin
                    next_state = SET_LEN_ADDR;
                end else begin
                    next_state = IDLE;
                end
            end

            // place ct_addr = 0 on the external CT memory
            SET_LEN_ADDR: begin
                next_state = CAPTURE_LEN;
            end

            // ct_rddata now corresponds to ct[0]
            // if the length is 0 then there is no payload to copy
            // otherwise begin copying ct[1] through ct[length]
            CAPTURE_LEN: begin
                if (ct_rddata == 8'd0) begin
                    next_state = START_CORES;
                end else begin
                    next_state = SET_CT_ADDR;
                end
            end

            // place ct_addr = ct_copy_index on the external CT memory
            SET_CT_ADDR: begin
                next_state = COPY_CT_BYTE;
            end

            // ct_rddata now corresponds to ct[ct_copy_index]
            // copy that byte into ct1 and ct2
            // if this was the final ciphertext byte then launch the crack cores next
            COPY_CT_BYTE: begin
                if (ct_copy_index == ct_length) begin
                    next_state = START_CORES;
                end else begin
                    next_state = SET_CT_ADDR;
                end
            end

            // pulse the crack cores once they are both ready
            START_CORES: begin
                if (c1_rdy && c2_rdy) begin
                    next_state = WAIT_FOR_BUSY;
                end else begin
                    next_state = START_CORES;
                end
            end

            // after the start pulse we want to see both crack cores actually leave ready
            // this prevents confusion between "still idle" and "already finished"
            WAIT_FOR_BUSY: begin
                if (!c1_rdy && !c2_rdy) begin
                    next_state = WAIT_FOR_CORES;
                end else begin
                    next_state = WAIT_FOR_BUSY;
                end
            end

            // wait for either crack core to succeed
            // or if both become ready with no winner then the whole search failed
            WAIT_FOR_CORES: begin
                if (c1_rdy && c1_key_valid) begin
                    next_state = SET_PT_ADDR;
                end else if (c2_rdy && c2_key_valid) begin
                    next_state = SET_PT_ADDR;
                end else if (c1_rdy && c2_rdy) begin
                    next_state = DONE;
                end else begin
                    next_state = WAIT_FOR_CORES;
                end
            end

            // drive the PT read address into the winning crack core
            SET_PT_ADDR: begin
                next_state = COPY_PT_BYTE;
            end

            // winner_pt_data now corresponds to the selected PT index
            // first copy the length byte then copy the payload bytes
            COPY_PT_BYTE: begin
                if (pt_copy_index == 8'd0) begin
                    if (winner_pt_data == 8'd0) begin
                        next_state = DONE;
                    end else begin
                        next_state = SET_PT_ADDR;
                    end
                end else begin
                    if (pt_copy_index == pt_copy_length) begin
                        next_state = DONE;
                    end else begin
                        next_state = SET_PT_ADDR;
                    end
                end
            end

            // final ready state
            DONE: begin
                if (en) begin
                    next_state = SET_LEN_ADDR;
                end else begin
                    next_state = DONE;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // sequential logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            // reset puts doublecrack back into a clean idle state
            state <= IDLE;
            found_key <= 24'd0;
            success_found <= 1'b0;
            winner_is_c1 <= 1'b1;
            ct_length <= 8'd0;
            ct_copy_index <= 8'd0;
            pt_copy_index <= 8'd0;
            pt_copy_length <= 8'd0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    // on a fresh request clear all signals
                    // we are about to re copy CT, relaunch both crack cores,
                    // and possibly recopy the winning PT into the shared PT
                    if (en) begin
                        found_key <= 24'd0;
                        success_found <= 1'b0;
                        winner_is_c1 <= 1'b1;
                        ct_length <= 8'd0;
                        ct_copy_index <= 8'd0;
                        pt_copy_index <= 8'd0;
                        pt_copy_length <= 8'd0;
                    end
                end

                SET_LEN_ADDR: begin
                    // nothing to latch here
                    // we are just giving the external CT memory a cycle with addr = 0
                end

                CAPTURE_LEN: begin
                    // ct_rddata now holds ct[0]
                    // store the length and prepare to start copying from index 1 next
                    ct_length <= ct_rddata;
                    ct_copy_index <= 8'd1;
                end

                SET_CT_ADDR: begin
                    // nothing to latch here
                    // we are just giving the external CT memory a cycle with addr = ct_copy_index
                end

                COPY_CT_BYTE: begin
                    // we just copied ct[ct_copy_index] into ct1 and ct2
                    // if we are not done yet then move to the next byte
                    if (ct_copy_index != ct_length) begin
                        ct_copy_index <= ct_copy_index + 8'd1;
                    end
                end

                START_CORES: begin
                    // nothing extra needed here
                    // the one cycle start pulse is generated in the combinational block below
                end

                WAIT_FOR_BUSY: begin
                    // nothing extra needed here either
                    // we are just waiting until both cores have visibly left ready
                end

                WAIT_FOR_CORES: begin
                    if (c1_rdy && c1_key_valid) begin
                        // c1 won so we save the key and prepare to start copying c1.pt into dc.pt
                        winner_is_c1 <= 1'b1;
                        found_key <= c1_key;
                        success_found <= 1'b1;
                        pt_copy_index <= 8'd0;
                        pt_copy_length <= 8'd0;
                    end else if (c2_rdy && c2_key_valid) begin
                        // c2 won and we do the same thing as above
                        winner_is_c1 <= 1'b0;
                        found_key <= c2_key;
                        success_found <= 1'b1;
                        pt_copy_index <= 8'd0;
                        pt_copy_length <= 8'd0;
                    end else if (c1_rdy && c2_rdy) begin
                        // both finished and neither found a valid key
                        found_key <= 24'd0;
                        success_found <= 1'b0;
                    end
                end

                SET_PT_ADDR: begin
                    // nothing to latch here
                    // we are just giving the winning crack core's PT memory a cycle
                    // so winner_pt_data matches pt_copy_index on the next state
                end

                COPY_PT_BYTE: begin
                    // we are copying from either c1.pt or c2.pt into dc.pt
                    // if pt_copy_index = 0 then winner_pt_data is the length prefix
                    // store that in pt_copy_length and then continue with payload bytes
                    if (pt_copy_index == 8'd0) begin
                        pt_copy_length <= winner_pt_data;

                        if (winner_pt_data != 8'd0) begin
                            pt_copy_index <= 8'd1;
                        end
                    end else begin
                        if (pt_copy_index != pt_copy_length) begin
                            pt_copy_index <= pt_copy_index + 8'd1;
                        end
                    end
                end

                DONE: begin
                    // if another request arrives while done clear everything and start over
                    // note that task5 normally starts this only once after reset
                    // so in normal board usage this is mainly a clean terminal state
                    if (en) begin
                        found_key <= 24'd0;
                        success_found <= 1'b0;
                        winner_is_c1 <= 1'b1;
                        ct_length <= 8'd0;
                        ct_copy_index <= 8'd0;
                        pt_copy_index <= 8'd0;
                        pt_copy_length <= 8'd0;
                    end
                end

                default: begin
                    // good practice but nothing needed
                end
            endcase
        end
    end

    // External CT address logic
    // doublecrack only uses the one external CT port while copying the ciphertext into ct1 and ct2
    // so we will handle the addr based on the state we're in here
    always_comb begin
        ct_addr = 8'd0;

        case (state)
            SET_LEN_ADDR: begin
                ct_addr = 8'd0;
            end

            SET_CT_ADDR: begin
                ct_addr = ct_copy_index;
            end

            default: begin
                ct_addr = 8'd0;
            end
        endcase
    end

    // PRIVATE CT memory muxes
    // During CAPTURE_LEN and COPY_CT_BYTE we are filling ct1 and ct2 from the one external CT port
    // during the actual cracking phase c1 reads from ct1 and c2 reads from ct2
    // so these muxes switch the private memories between write mode and read mode
    always_comb begin
        // defaults
        ct1_addr = 8'd0;
        ct1_wrdata = 8'd0;
        ct1_wren = 1'b0;

        ct2_addr = 8'd0;
        ct2_wrdata = 8'd0;
        ct2_wren = 1'b0;

        case (state)
            // copy ct[0] into both private CT memories
            CAPTURE_LEN: begin
                ct1_addr = 8'd0;
                ct1_wrdata = ct_rddata;
                ct1_wren = 1'b1;

                ct2_addr = 8'd0;
                ct2_wrdata = ct_rddata;
                ct2_wren = 1'b1;
            end

            // copy ct[1] through ct[length] into both private CT memories
            COPY_CT_BYTE: begin
                ct1_addr = ct_copy_index;
                ct1_wrdata = ct_rddata;
                ct1_wren = 1'b1;

                ct2_addr = ct_copy_index;
                ct2_wrdata = ct_rddata;
                ct2_wren = 1'b1;
            end

            // once copying is done the private memories switch to read mode
            // and each crack core drives its own CT address
            default: begin
                ct1_addr = c1_ct_addr;
                ct1_wrdata = 8'd0;
                ct1_wren = 1'b0;

                ct2_addr = c2_ct_addr;
                ct2_wrdata = 8'd0;
                ct2_wren = 1'b0;
            end
        endcase
    end

    // SHARED PT memory mux
    // the shared PT memory only needs to contain the final winning plaintext
    // so we only write to it during COPY_PT_BYTE and copy one byte at a time
    always_comb begin
        // defaults
        pt_addr = 8'd0;
        pt_wrdata = 8'd0;
        pt_wren = 1'b0;

        if (state == COPY_PT_BYTE) begin
            pt_addr = pt_copy_index;
            pt_wrdata = winner_pt_data;
            pt_wren = 1'b1;
        end
    end

    // Start pulses for the two crack cores
    // both cores should start together and they both launch only when both are ready
    always_comb begin
        c1_en = 1'b0;
        c2_en = 1'b0;

        if (state == START_CORES && c1_rdy && c2_rdy) begin
            c1_en = 1'b1;
            c2_en = 1'b1;
        end
    end

    // PT readback addresses into c1 and c2
    // crack exposes its internal PT memory through pt_rd_addr and pt_rddata
    // during the copy phase we only really use the winning core's data
    // but driving both read addresses the same way keeps the logic simple
    assign c1_pt_rd_addr = pt_copy_index;
    assign c2_pt_rd_addr = pt_copy_index;

    // OUTPUTS

    // ready only when this module can report the current request is done
    // for task5 top level this lets the board show the key as soon as the winner is known
    assign rdy = (state == IDLE) || (state == DONE);

    // key only meaningful after a succesful finish
    assign key = found_key;

    // key_valid only goes high if the whole search finished succesffuly
    assign key_valid = (state == DONE && success_found);

    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(
        .address(pt_addr),
        .clock(clk),
        .data(pt_wrdata),
        .wren(pt_wren),
        .q()
    );

    // private ciphertext copies
    ct_mem ct1(
        .address(ct1_addr),
        .clock(clk),
        .data(ct1_wrdata),
        .wren(ct1_wren),
        .q(ct1_q)
    );

    ct_mem ct2(
        .address(ct2_addr),
        .clock(clk),
        .data(ct2_wrdata),
        .wren(ct2_wren),
        .q(ct2_q)
    );

    // c1 checks even keys
    crack c1(
        .clk(clk),
        .rst_n(rst_n),
        .en(c1_en),
        .rdy(c1_rdy),
        .key(c1_key),
        .key_valid(c1_key_valid),
        .ct_addr(c1_ct_addr),
        .ct_rddata(ct1_q),
        .start_key(24'h000000),
        .key_step(24'd2),
        .pt_rd_addr(c1_pt_rd_addr),
        .pt_rddata(c1_pt_rddata)
    );

    // c2 checks odd keys
    crack c2(
        .clk(clk),
        .rst_n(rst_n),
        .en(c2_en),
        .rdy(c2_rdy),
        .key(c2_key),
        .key_valid(c2_key_valid),
        .ct_addr(c2_ct_addr),
        .ct_rddata(ct2_q),
        .start_key(24'h000001),
        .key_step(24'd2),
        .pt_rd_addr(c2_pt_rd_addr),
        .pt_rddata(c2_pt_rddata)
    );

endmodule : doublecrack