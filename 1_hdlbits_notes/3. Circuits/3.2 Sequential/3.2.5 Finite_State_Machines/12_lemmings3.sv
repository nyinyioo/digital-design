module top_module(
    input clk,
    input areset,
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output reg walk_left,
    output reg walk_right,
    output reg aaah,
    output reg digging
);

/*
    WL = walking left
    WR = walking right 
    FL = falling, walking left
    FR = falling, walking right
    DL = Digging left
    DR = digging right
*/


    typedef enum logic [2:0] {
        WL = 3'd0,
        WR = 3'd1,
        FL = 3'd2,
        FR = 3'd3,
        DL = 3'd4,
        DR = 3'd5
    } state_t;

    state_t state, next_state;

    // Next-state logic
    always_comb begin
        unique case (state)
            WL: begin
                if (!ground)          next_state = FL;
                else if (dig)         next_state = DL;
                else if (bump_left)   next_state = WR;
                else                  next_state = WL;
            end

            WR: begin
                if (!ground)          next_state = FR;
                else if (dig)         next_state = DR;
                else if (bump_right)  next_state = WL;
                else                  next_state = WR;
            end

            FL: begin
                if (ground)           next_state = WL;
                else                  next_state = FL;
            end

            FR: begin
                if (ground)           next_state = WR;
                else                  next_state = FR;
            end

            DL: begin
                if (!ground)          next_state = FL;
                else                  next_state = DL;
            end

            DR: begin
                if (!ground)          next_state = FR;
                else                  next_state = DR;
            end

            default: next_state = WL;
        endcase
    end

    // State register
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= WL;  
        else
            state <= next_state;
    end

    // Output logic
    always_comb begin
        walk_left  = 0;
        walk_right = 0;
        aaah       = 0;
        digging    = 0;

        unique case (state)
            WL: walk_left  = 1;
            WR: walk_right = 1;
            FL: aaah       = 1;
            FR: aaah       = 1;
            DL: digging    = 1;
            DR: digging    = 1;
        endcase
    end
    
endmodule