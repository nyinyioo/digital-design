module task2(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);


   /*
        task2 top level

        For task 2 we need to instantiate:
        - the S memory
        - init from task 1
        - ksa from task 2

        Also note from the handout:
        - only the top-level should hardwire key[23:10] to 0
        - SW[9:0] becomes key[9:0]
        - on reset we must first run init and then ksa
        - we should not rely on exact timing of the other modules
          and instead use the ready/enable microprotocol properly
    */

    // reset is active low and comes from KEY[3]
    logic rst_n;

    // 24-bit key passed into ksa
    logic [23:0] key;

    // init signals
    logic init_en;
    logic init_rdy;
    logic [7:0] init_addr;
    logic [7:0] init_wrdata;
    logic init_wren;

    // ksa signals
    logic ksa_en;
    logic ksa_rdy;
    logic [7:0] ksa_addr;
    logic [7:0] ksa_rddata;
    logic [7:0] ksa_wrdata;
    logic ksa_wren;

    // shared S memory signals
    logic [7:0] mem_addr;
    logic [7:0] mem_wrdata;
    logic mem_wren;
    logic [7:0] mem_q;

    // Small top level fsm 
    typedef enum logic [2:0] {
        START_INIT, // Send one request to init 
        WAIT_INIT, // wait for init to finish 
        START_KSA, // send one request to ksa 
        WAIT_KSA, // wait for ksa to finish 
        DONE // stop doing anything else 
    } state_t;

    state_t state, next_state;

    // assign reset and key
    assign rst_n = KEY[3];
    assign key = {14'd0, SW[9:0]};

    // next-state logic for the top-level controller
    always_comb begin
        case (state)
            START_INIT: begin
                // If init is ready, pulse en this cycle and then move on
                if (init_rdy) begin
                    next_state = WAIT_INIT;
                end else begin
                    next_state = START_INIT;
                end
            end

            WAIT_INIT: begin
                // init accepted the request already now we just wait until it becomes ready 
                // again, which means the initialization finished
                if (init_rdy) begin
                    next_state = START_KSA;
                end else begin
                    next_state = WAIT_INIT;
                end
            end

            START_KSA: begin
                // same idea as init: wait until ksa is ready and pulse en once
                if (ksa_rdy) begin
                    next_state = WAIT_KSA;
                end else begin
                    next_state = START_KSA;
                end
            end

            WAIT_KSA: begin
                // ksa is busy so once it retunrs to ready task 2 is done 
                if (ksa_rdy) begin
                    next_state = DONE;
                end else begin
                    next_state = WAIT_KSA;
                end
            end

            DONE: begin
                next_state = DONE;
            end

            default: begin
                next_state = START_INIT;
            end
        endcase
    end

    // state register
    always_ff @(posedge CLOCK_50) begin
        if (!rst_n) begin
            state <= START_INIT;
        end else begin
            state <= next_state;
        end
    end


    // generate the enable pulsees
    always_comb begin
        init_en = 1'b0;
        ksa_en = 1'b0;

        case (state)
            START_INIT: begin
                if (init_rdy) begin
                    init_en = 1'b1;
                end
            end

            START_KSA: begin
                if (ksa_rdy) begin
                    ksa_en = 1'b1;
                end
            end

            default: begin
                init_en = 1'b0;
                ksa_en = 1'b0;
            end
        endcase
    end

 
    // Note that since init and ksa both want to control the same S memory, 
    // we need a mux for the RAM inputs. While init is the active phase, S memory listens to init 
    // and while ksa is the active phase, S mem listens to ksa. 
    always_comb begin
        mem_addr = 8'd0;
        mem_wrdata = 8'd0;
        mem_wren = 1'b0;

        case (state)
            START_INIT, WAIT_INIT: begin
                mem_addr = init_addr;
                mem_wrdata = init_wrdata;
                mem_wren = init_wren;
            end

            START_KSA, WAIT_KSA: begin
                mem_addr = ksa_addr;
                mem_wrdata = ksa_wrdata;
                mem_wren = ksa_wren;
            end

            default: begin
                mem_addr = 8'd0;
                mem_wrdata = 8'd0;
                mem_wren = 1'b0;
            end
        endcase
    end

    // init module from task 1
    init u_init(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(init_en),
        .rdy(init_rdy),
        .addr(init_addr),
        .wrdata(init_wrdata),
        .wren(init_wren)
    );

    // ksa module
    ksa u_ksa(
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(ksa_en),
        .rdy(ksa_rdy),
        .key(key),
        .addr(ksa_addr),
        .rddata(ksa_rddata),
        .wrdata(ksa_wrdata),
        .wren(ksa_wren)
    );
    
    // port init 
    s_mem s(
        .address(mem_addr),
        .clock(CLOCK_50),
        .data(mem_wrdata),
        .wren(mem_wren),
        .q(mem_q)
    );

    // Feed the memory read data into ksa
    assign ksa_rddata = mem_q;

endmodule : task2