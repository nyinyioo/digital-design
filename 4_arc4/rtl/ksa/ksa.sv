module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

  /*
        Our ARC4 Key-Scheduling Algorithm 
        ARC4 KSA pseudocode:
            j = 0
            for i = 0 to 255:
                j = (j + s[i] + key[i mod 3]) mod 256
                swap s[i] and s[j]

        This module will also follow the ready/enable microprotocol, however we do not perform initialization here.
        We assume S has already been initialized elsewhere to [0 - 255]. Here we control a single port S memory through 
        addr/wrdata/wren. The top-level module will be responsible for providing the 24-bit key.
        Also note that for task2.sv only the top-level hardwires key[23:10] = 0 and uses SW[9:0] for key[9:0]
    */

    // States
    typedef enum logic [2:0] {
        IDLE,    // waiting for request 
        READ_I,  // read s[i], compute new j 
        READ_J,  // read s[j]
        WRITE_I, // write s[i] = old s[j]
        WRITE_J  // write s[j] = old s[i], then advance loop 
    } state_t;

    state_t state, next_state;

    // Outer KSA loop index
    logic [7:0] i;

    // Current j from the ARC4 algorithm
    logic [7:0] j;

    // New computed j for the current iteration
    logic [7:0] j_new;

    // temp register to hold s[i] during swap
    // captured in READ_J, used as wrdata in WRITE_J
    logic [7:0] si;

    // Since the KSA uses key[i mod 3], we do not need to recompute i%3 from scratch every cycle.
    // We can simply just rotate through: 0 -> key[23:16], 1 -> key[15:8] and 2 -> key[7:0] 
    // So we will use key_sel to track which of the 3 key bytes to use 
    logic [1:0] key_sel;
    logic [7:0] key_byte;   


    always_comb begin
        j_new = j + rddata + key_byte;  
    end

    // Pick the current key byte based on key_sel, also just note that ARC4 key bytes are big endian 
    always_comb begin
        key_sel = i % 3;             
        case (key_sel)
            2'd0: key_byte = key[23:16];
            2'd1: key_byte = key[15:8];
            default: key_byte = key[7:0];
        endcase
    end

    // Next-state logic
    always_comb begin
        case (state)
            // our ready/en protocol similar to init in task 1
            IDLE: begin
                if (en) begin
                    next_state = READ_I;
                end else begin
                    next_state = IDLE;
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
            WRITE_I: begin
                next_state = WRITE_J;
            end

            // Second half of swap: s[j_new] = old s[i]
            // After that write we check if i is 255 if so ksa is done and we return to idle
            // else we advance i and continue the next iteration
            WRITE_J: begin
                if (i == 8'hff) begin
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
        end 
        else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    // If we get a new req start the ksa fresh so reset all the signals
                    // and note that en works in idle as rdy is high and once we accept a request we will 
                    // become busy on the next cycle
                    if (en) begin
                        i <= 8'd0;
                        j <= 8'd0;
                        si <= 8'd0;
                    end
                end

                READ_I: begin
                    // nothing to latch here 
                    // memory has one cycle of read latency
                    // addr = i is set in output logic, 
                    // rddata = s[i] will be valid next cycle in READ_J
                end

                READ_J: begin
                    // rddata = s[i] is now valid 
                    // capture si from rddata for WRITE_J
                    si <= rddata;

                    // compute j = (old_j + s[i] + key[i mod 3]) mod 256
                    // j still holds old value and rddata = s[i], 
                    // combinational output sets addr = j_new to prefetch s[j] for WRITE_I
                    // after this clock edge j holds the new value for swap for WRITE_J
                    j  <= j_new;
                end

                WRITE_I: begin
                    // nothing to latch 
                    // rddata = s[j] used directly 
                    // as wrdata in output logic
                end

                WRITE_J: begin

                    // counter logic 
                    if (i != 8'hff) begin
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
        // Safe defaults
        rdy = 1'b0;
        addr = 8'd0;
        wrdata = 8'd0;
        wren = 1'b0;

        case (state)
            IDLE: begin
                // rdy asserted high to accept request
                rdy = 1'b1;
                addr = i;
            end

            READ_I: begin
                // Read s[i]
                addr = i;
            end

            READ_J: begin
                // Read s[j_new]
                addr = j_new;
            end

            WRITE_I: begin
                // begin swap s[i] = s[j]
                // rddata = s[j] value set in READ_J with j_new addr 
                // set wrdata = rddata 
                addr = i;
                wrdata = rddata;
                wren = 1'b1;
            end

            WRITE_J: begin
                // complete swap: s[j] = s[i]
                // si = s[i] value set in READ_J (SEQ BLOCK)
                // j = j_new addr from READ_J (SEQ BLOCK)
                addr = j;
                wrdata = si;
                wren = 1'b1;
            end

            default: begin
                rdy = 1'b0;
                addr = 8'd0;
                wrdata = 8'd0;
                wren = 1'b0;
            end
        endcase
    end

endmodule : ksa