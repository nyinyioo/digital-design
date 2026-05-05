module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

    /*
        Our ARC4 (Pseudo Random Generation Algorithm)
        PRGA pseudocode:
            i = 0, j = 0
            message_length = ciphertext[0]
            plaintext[0] = message_length

            for k = 1 to message_length:
                i = (i + 1) mod 256
                j = (j + s[i]) mod 256
                swap s[i] and s[j]
                pad = s[(s[i] + s[j]) mod 256]
                plaintext[k] = pad XOR ciphertext[k]

        This module follows the ready/enable microprotocol. We assume S has 
        already been initialized by init.sv and scrambled by ksa.sv.

        The PRGA module reads S memory to compute pad (keystream bytes) and 
        XORs with CT (ciphertext) to produce PT (plaintext) output.

        S memory is single port, controlled through addr/wrdata/wren.
        CT memory is read-only(address), PT memory is write-only (addr/wrdata/wren.).
    */

    // state assignments
    typedef enum logic [3:0] {
        IDLE, // waiting for request
        READ_CT_0, // set ct_addr = 0, wait for CT[0] to be valid next cycle
        WRITE_PT_0, // ct_rddata = CT[0] valid, latch msg_len, write PT[0] = msg_len, increment i
        READ_I, // set s_addr = i, wait for s[i] to be valid next cycle
        READ_J, // s_rddata = s[i] valid, latch si, compute j = old_j + s[i], set s_addr = j_new
        WRITE_I, // s_rddata = s[j] valid, latch sj, write s[i] = s[j] (first half of swap)
        WRITE_J, // write s[j] = si (second half of swap), prefetch CT[k] via ct_addr = k
        READ_PAD, // s_rddata = s[j] valid, set s_addr = si + sj, keep ct_addr = k
        WRITE_PT // s_rddata = pad valid, ct_rddata = CT[k] valid, write PT[k] = pad ^ CT[k], increment i and k
    } state_t;
    state_t state, next_state;

    // Outer KSA loop index
    logic [7:0] i;

    // Current j from the ARC4 algorithm
    logic [7:0] j;

    // New computed j for the current iteration
    logic [7:0] j_new;

    // temp registers during swap
    // latch during READ_J and WRITE_I
    logic [7:0] si;
    logic [7:0] sj;

    // prga internal signals 
    logic [7:0] k;
    logic [7:0] msg_len;


    always_comb begin
        j_new = j + s_rddata; 
    end

    // Next-state logic
    always_comb begin

        case (state)
            // our ready/en protocol similar to init in task 1
            IDLE: begin
                if (en) begin
                    next_state = READ_CT_0;
                end else begin
                    next_state = IDLE;
                end
            end

            // wait for CT[0] to be valid
            READ_CT_0: begin
                next_state = WRITE_PT_0; 
            end

            // start PRGA Loop
            WRITE_PT_0: begin
                // if length is 0 we should write it and then be done immediately 
                if (ct_rddata == 8'd0) begin
                    next_state = IDLE;
                end else begin
                    next_state = READ_I;
                end
            end
            

            // After reading s[i], we move to the state that reads s[j_new]
            READ_I: begin
                next_state = READ_J;
            end

            // After reading s[j_new], we can perform the first write
            READ_J: begin
                next_state = WRITE_I;
            end

            // First half of swap: s[i] = old s[j]
            // prefetch CT[k]
            WRITE_I: begin
                next_state = WRITE_J;
            end

            // finish swap: s[j] = si
            WRITE_J: begin
                next_state = READ_PAD;
            end 

            // wait for PAD[0] to be valid
            READ_PAD: begin
                next_state = WRITE_PT;
            end

            // write to PT[0]
            WRITE_PT: begin
                if (k == msg_len) begin
                    next_state = IDLE;
                end else begin
                    next_state = READ_I; 
                end

            end

            // default state: IDLE
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic: we will handle state and the datapath registers 
    always_ff @(posedge clk) begin
        // check if we need to reset everything 
        if (!rst_n) begin
            state <= IDLE;
            i <= 8'd0;
            j <= 8'd0;
            si <= 8'd0;
            sj <= 8'd0;
            k <= 8'd1; 
            msg_len <= 8'd0; 
        end 
        else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (en) begin
                        i <= 8'd0;
                        j <= 8'd0;
                        si <= 8'd0;
                        k <= 8'd1;
                        msg_len <= 8'd0;
                    end
                end

                READ_CT_0: begin
                    // nothing to latch here 
                    // memory has one cycle of read latency
                    // addr = i is set in output logic, 
                    // ct_rddata = CT[0] will be valid next cycle in WRITE_CT_0
                end

                WRITE_PT_0: begin
                    msg_len <= ct_rddata;  // latch message length
                    i <= i + 8'd1;   // pre increment i
                end

                READ_I: begin
                    // nothing to latch here 
                    // memory has one cycle of read latency
                    // addr = i is set in output logic, 
                    // rddata = s[i] will be valid next cycle in READ_J
                end

                READ_J: begin
                    // rddata = s[i] is now valid 
                    // latch si from rddata for WRITE_J
                    si <= s_rddata;

                    // compute j_new = j + s_rddata
                    // j still holds old value and rddata = s[i], 
                    // combinational output sets addr = j_new to prefetch s[j] for WRITE_I
                    // after this clock edge j holds the new value for swap for WRITE_J
                    j  <= j_new;
                end

                WRITE_I: begin
                    // latch sj from rddata for WRITE_J
                    sj <= s_rddata;
                end

                WRITE_J: begin
                   
                end

                READ_PAD: begin
                    // s_rddata = s[j] after WRITE_J
                    // addr = (si + s_rddata) set in output logic
                    // pad will be valid next cycle in WRITE_PT
                end

                WRITE_PT: begin
                    // s_rddata = pad = s[(s[i]+s[j]) mod 256]
                    
                    // increment i and k
                    if (k != msg_len) begin
                        k <= k + 8'd1;
                        i <= i + 8'd1;
                    end
                end

                default: begin
                    // Nothing extra needed just good practice 
                end
            endcase
        end
    end


    // Output logic
    always_comb begin
        
        // initialize inputs
        rdy = 1'b0;
        s_addr = 8'd0;
        s_wrdata = 8'd0;
        s_wren = 1'b0;
        ct_addr = 8'd0;
        pt_addr = 8'd0;
        pt_wrdata = 8'd0;
        pt_wren = 1'b0;

        case (state)
            IDLE: begin
                // rdy asserted high to accept request
                rdy = 1'b1;
                s_addr = 8'd0;
            end

            READ_CT_0: begin
                ct_addr = 8'd0; // read CT[0] at addr = 0
            end

            WRITE_PT_0: begin
                // CT[0] = msg_len now valid
                pt_addr = 8'd0;
                pt_wrdata = ct_rddata;  // PT[0] = msg_len
                pt_wren = 1'b1;
            end

            READ_I: begin
                // Read s[i]
                s_addr = i;
            end

            READ_J: begin
                // Read s[j_new]
                s_addr = j_new;
            end

            WRITE_I: begin
                // begin swap s[i] = s[j]
                // rddata = s[j] value set in READ_J with j_new addr 
                // set wrdata = rddata 
                s_addr = i;
                s_wrdata = s_rddata;
                s_wren = 1'b1;
            end

            WRITE_J: begin
                // complete swap: s[j] = s[i]
                // si = s[i] value set in READ_J (SEQ BLOCK)
                // j = j_new addr from READ_J (SEQ BLOCK)
                s_addr = j;
                s_wrdata = si;
                s_wren = 1'b1;
                ct_addr = k;  // prefetch CT[k] so it's valid in READ_PAD
            end

            READ_PAD: begin
                s_addr = si + sj;  
                ct_addr = k; 
            end

            WRITE_PT: begin
                // s_rddata = pad = s[(si + sj) mod 256], valid from READ_PAD
                // ct_rddata = CT[k], valid from READ_PAD 
                pt_addr = k;
                pt_wrdata = s_rddata ^ ct_rddata;
                pt_wren = 1'b1;
            end

        endcase
    end

endmodule: prga
