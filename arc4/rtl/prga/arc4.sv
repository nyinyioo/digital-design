module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);


    // state assignments
    typedef enum logic [1:0] {
        IDLE,
        INIT,
        KSA,
        PRGA
    } state_t;
    state_t state, next_state;


    // declare internals signanls

    // signals for s_mem module
    logic [7:0] s_addr, s_rddata, s_wrdata;
    logic s_wren;

    // signals for init module
    logic init_en, init_rdy;
    logic [7:0] init_addr, init_wrdata;
    logic init_wren;

    // signals for ksa module
    logic ksa_en, ksa_rdy;
    logic [7:0] ksa_addr, ksa_rddata, ksa_wrdata;
    logic ksa_wren;

    // shared signals for prga module
    logic prga_en, prga_rdy;
    logic [7:0] prga_s_addr, prga_s_rddata, prga_s_wrdata;
    logic prga_s_wren;


    // s_mem module
    s_mem s(
        .address(s_addr),
        .clock(clk),
        .data(s_wrdata),
        .wren(s_wren),
        .q(s_rddata)
    );

     // init module
    init i(
        .clk(clk),
        .rst_n(rst_n),
        .en(init_en),
        .rdy(init_rdy),
        .addr(init_addr),
        .wrdata(init_wrdata),
        .wren(init_wren)
    );

    // ksa module
    ksa k(
        .clk(clk),
        .rst_n(rst_n),
        .en(ksa_en),
        .rdy(ksa_rdy),
        .key(key),
        .addr(ksa_addr),
        .rddata(s_rddata),
        .wrdata(ksa_wrdata),
        .wren(ksa_wren)
    );

    // prga module
    prga p( 
        .clk(clk),
        .rst_n(rst_n),
        .en(prga_en),
        .rdy(prga_rdy),
        .key(key),
        .s_addr(prga_s_addr),    
        .s_rddata(s_rddata),     
        .s_wrdata(prga_s_wrdata), 
        .s_wren(prga_s_wren),    
        .ct_addr(ct_addr),
        .ct_rddata(ct_rddata),
        .pt_addr(pt_addr),
        .pt_rddata(pt_rddata),
        .pt_wrdata(pt_wrdata),
        .pt_wren(pt_wren)
    );


    // Input CL Block
    // - implements the ready/enable microprotocol between each submodule in arc4.
    // - each submodule also follows the ready/enable microprotocol
    // - arc4 will waits for each submodule to finish (rdy = 1) and then transition.
    always_comb begin 
        case (state)
            IDLE: begin 
                 // arc4 is ready to accept a request
                 // when en is asserted, transition to INIT 
                if (en) next_state = INIT;          
                else    next_state = IDLE; 
            end

            INIT: begin 
                // initializes s_mem with identity 
                if (init_rdy) next_state = KSA;     
                else          next_state = INIT;
            end

            KSA: begin 
                // scramble the s_mem array 
                // using the key scheduling algorithm
                if (ksa_rdy) next_state = PRGA;   
                else         next_state = KSA;
            end

            PRGA: begin 
                // generates keystream from scrambled s_mem
                // XORs keystream with ct_mem to produce plaintext
                // writes decrypted plaintext to pt_mem
                if (prga_rdy) next_state = IDLE;   
                else          next_state = PRGA;  
            end

            default: next_state = IDLE;
        endcase
    end

    // Sequential NS Block
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Output CL Block
    // - datapath controls the enable signals for each submodule
    // - asserts s_mem signals (addr/wrdata/wren)
    // - based on the current state to each submodule
    always_comb begin 
        // defaults values
        rdy = 1'b0;
        init_en = 1'b0;
        ksa_en = 1'b0;
        prga_en = 1'b0;
        s_addr = 8'd0; 
        s_wrdata = 8'd0; 
        s_wren = 1'b0;

        case (state)
            IDLE: begin
                rdy = 1'b1;
                init_en = en; // pass en signal to init
            end

            INIT: begin 
                s_addr = init_addr;  
                s_wrdata = init_wrdata;  
                s_wren = init_wren;
                ksa_en = init_rdy; // after init finishes, start ksa
            end

            KSA: begin 
                s_addr = ksa_addr;
                s_wrdata = ksa_wrdata;
                s_wren = ksa_wren;
                prga_en = ksa_rdy; // after ksa finishes, start prga
            end

            PRGA: begin 
                s_addr = prga_s_addr; 
                s_wrdata = prga_s_wrdata; 
                s_wren = prga_s_wren; 
                rdy = prga_rdy;   // after prga finishes, assert rdy to indicate arc4 is done and wait for the next en signal
            end                       
            default: begin 
                s_addr = 8'd0; 
                s_wrdata = 8'd0; 
                s_wren = 1'b0; 
            end
        endcase
    end
    
endmodule: arc4
