module task1(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    /* 
        This is our top level module for task 1 which connects the init module to the generated s_mem RAM.

        As stated in the readme: 
            - KEY[3] is our active low synchronous reset
            - init must be started exactly once after reset
            - after init finishes, no further writes should occur

        We will wait until init reports rdy = 1 after reset then send a one clock pulse 
        on init_en. 
    */


    // assign signals
    logic rst_n;
    logic [7:0] address;
    logic [7:0] data;
    logic wren;
    logic rdy;
    logic init_en; 
    logic started; 

    // reset input 
    assign rst_n = KEY[3];

    // We will generate exactly one enable pulse after reset. So we will keep init_en normally as 0 then once 
    // we see that init is ready and we have not started yet we will pulse init_en for once cycle. After we do this 
    // started will be set to 1 and then we won't be sending requests after that. This aligns w the lab handout 

    always_ff @(posedge CLOCK_50) begin 
        if (!rst_n) begin 
            init_en <= 1'b0; 
            started <= 1'b0; 
        end 
        else begin 
            // default no req
            init_en <= 1'b0; 

            // send exactly one req after res
            if (!started && rdy) begin 
                init_en <= 1'b1; 
                started <= 1'b1; 
            end 
        end 
    end 

    // INIT Module
    init u_init (
        .clk(CLOCK_50),
        .rst_n(rst_n),
        .en(init_en), 
        .rdy(rdy),
        .addr(address),
        .wrdata(data),
        .wren(wren)
    );

   // S_MEM Module
    s_mem s (
        .address(address),
        .clock(CLOCK_50),
        .data(data),
        .wren(wren),
        .q() 
    );

endmodule: task1