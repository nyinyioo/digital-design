module top_module(
    input clk,
    input areset,
    input ground,
    input bump_left,
    input bump_right,
    output reg walk_left,
    output reg walk_right,
    output reg aaah
);

/*
    WL = walking left
    WR = walking right 
    FL = falling, walking left
    FR = falling, walking right
*/

    typedef enum logic [1:0] {
        WL = 2'b00,
        WR = 2'b01,
        FL = 2'b10,
        FR = 2'b11
    } state_t;

    state_t state, next_state;

    // State transition logic
    always_comb begin
        case (state)
            WL: begin
                if (!ground)          next_state = FL;
                else if (bump_left)   next_state = WR;
                else                  next_state = WL;
            end

            WR: begin
                if (!ground)          next_state = FR;
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

        unique case (state)
            WL: walk_left  = 1;
            WR: walk_right = 1;
            FL: aaah       = 1;
            FR: aaah       = 1;
        endcase
    end

endmodule