module task3(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

   /*
        task3 top level: 
        
        for task2: 
        - in task2, init and ksa were separate modules, we had to: 
        - Instantiate `s_mem` itself
        - Mux the address/data/wren between `init` and `ksa`
        - handle the microprotocol handshakes properly

        for task3 top level: 
        - arc4 handles init, ksa, prga internally
        - we just need to instantiate arc4, ct_mem, pt_mem

        Additionally, as per handout: 
        - key[23:10] = 0
        - SW[9:0] = key[9:0]
    */


    // declare signals
    logic rst_n;       // active low reset from KEY[3]
    logic [23:0] key;  // 24-bit key passed into arc4

    assign rst_n = KEY[3];
    assign key = {14'd0, SW[9:0]}; // hardwire top 14 bits of key to 0 and use switches for the rest

    // arc4 signals
    logic arc4_en, arc4_rdy;
    logic [7:0] ct_addr, ct_rddata;
    logic [7:0] pt_addr, pt_rddata, pt_wrdata;
    logic pt_wren;

    // state assignment
    typedef enum logic [1:0]{ 
        START = 2'd0, // arc4_rdy = 1, waiting for arc4_en  = 1
        WAIT = 2'd1, // arc4 running, waiting for arc4_rdy = 1
        DONE = 2'd2 // stay
    } state_t;
    state_t state, next_state;

    // FSM - Input CL Block
    always_comb begin
        case (state)
            START: next_state = arc4_rdy ? WAIT : START;
            WAIT: next_state = arc4_rdy ? DONE : WAIT;
            DONE: next_state = DONE;
            default: next_state = START;
        endcase
    end

    // Sequential NS Block
    always_ff @(posedge CLOCK_50) begin 
        if (!rst_n) begin 
            state <= START; 
        end else begin
            state <= next_state;
        end
    end

    // Output CL Block
    always_comb begin
        // default
        arc4_en = 1'b0;

        case (state)
            START: begin
                // assert en to start arc4
                arc4_en = arc4_rdy;
            end
            WAIT: begin
                // wait for arc4 to finish
            end
            DONE: begin
                // nothing needed here 
            end
        endcase
    end


    // module instantiations

    // cipher text
    ct_mem ct(
        .address(ct_addr),
        .clock(CLOCK_50),
        .data(8'd0),
        .wren(1'b0),
        .q(ct_rddata)
    );

    // plain text
    pt_mem pt(
        .address(pt_addr),
        .clock(CLOCK_50),
        .data(pt_wrdata),
        .wren(pt_wren),
        .q(pt_rddata)
    );

    // arc4 module
    arc4 a4(
        .clk(CLOCK_50),
        .rst_n(rst_n), 
        .en(arc4_en),
        .rdy(arc4_rdy),
        .key(key),
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(pt_addr),
        .pt_rddata(pt_rddata),
        .pt_wrdata(pt_wrdata),
        .pt_wren(pt_wren)
    );


endmodule: task3
