module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

/*
    This module initializes a 256-RAM (s_mem) module with values 0-255. 
    Uses the ready/enable microprotocol and connects to the generated 
    s_mem in task1 toplevel. So we will perform this ARC4 initialization step in the readme:

        for i = 0 to 255:
            s[i] = i
    
    Note it does not contain the memory itself instead it drives the control signals of the external
    s_mem RAM.

    Ready/Enable Microprotocol:
        - when rdy = 1, this module is INIT and able to accept a request
        - if en = 1 while rdy = 1, that starts one intialization request
        - While the module is busy writing all 256 entries, rdy must be 0 
        - After the last write, the module returns to ready state (INIT)

    This will match the labs ready/enable rule where if rdy is high, the module 
    must be able to accept a request in that same cycle 

    Single Port RAM:
        address : write address
        wrdata : write data
        wren : write enable
        q : read data (unused here)
        write : @posedge clk, if wren -> s_mem[address] = wrdata
        read : @posedge clk, q <= s_mem[address]
*/

    // state assignments  
    typedef enum logic {
        INIT, // waiting for a request 
        WRITE // currently filling s[i] = i
    } state_t;
    
    state_t state, next_state;

    // internal signals
    // i is the current memory index being written 
    logic [7:0] i;

    // Our combinational next state logic 
    always_comb begin
        case (state)
            // Stay INIT until a valid request arrives.
            INIT: begin
                if (en) begin
                    next_state = WRITE;
                end 
                else begin
                    next_state = INIT;
                end
            end

            // Keep writing until the final entry s[255] is reached.
            WRITE: begin
                if (i == 8'd255) begin
                    next_state = INIT;
                end else begin
                    next_state = WRITE;
                end
            end

            default: begin
                next_state = INIT;
            end
        endcase
    end

    // Sequential state and counter update 
    always@(posedge clk) begin
        if (!rst_n) begin
            state <= INIT;
            i <= 8'd0; 
        end 
        else begin
            state <= next_state;

            case (state)
                INIT: begin 
                    // When a new request is accepted, restart from address 0 
                    // we do this here so that on the first write cycle, addr = 0 and wrdata = 0
                    if (en) begin 
                        i <= 8'd0; 
                    end 
                end 

                WRITE: begin 
                    // increment after each write but remmember not to wrap after 255 cuz
                    // on the cycle where i = 255, that final write will still happen and then the FSM will return to INIT
                    if (i != 8'd255) begin 
                        i <= i + 8'd1;
                    end
                end

                default: begin 
                    i <= i; // for clean code 
                end 
            endcase
        end
    end

    // OUTPUT LOGIC
    // Assign outputs: during Write we write address i with the value i and 
    // during INIT these buses aren't being used we will set wren = 0 to prevent any write 
    assign addr = i;
    assign wrdata = i;
    assign wren = (state == WRITE);

    // Ready is high only when INIT and able to accept a new request 
    assign rdy = (state == INIT);

endmodule: init

