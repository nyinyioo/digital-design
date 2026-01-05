

module top_module(
    input clk,
    input areset,    // Freshly brainwashed Lemmings walk left.
    input bump_left,
    input bump_right,
    input ground,
    input dig,
    output logic walk_left,
    output logic walk_right,
    output logic aaah,
    output logic digging ); 

/*
    WL = walking left
    WR = walking right 
    FL = falling, walking left
    FR = falling, walking right
    DL = Digging left
    DR = digging right
    SPLAT = splatter
*/


    parameter WL = 3'd0;
    parameter WR = 3'd1;
    parameter FL = 3'd2;
    parameter FR = 3'd3;
    parameter DL = 3'd4;
    parameter DR = 3'd5;
    parameter SPLAT = 3'd6;

    
    logic [2:0] state, next_state;
    logic [4:0] fall_count_left, fall_count_right;

    // Next-state logic
    always @(*) begin
        case (state)

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

                if (ground) begin
                    next_state = WL;
                end else
                    if (fall_count_left >= 5'd20) next_state = SPLAT;
                    else        next_state = FL;

            end

            FR: begin
                if (ground) begin
                    next_state = WR;
                end else
                    if (fall_count_right >= 5'd20) next_state = SPLAT;
                    else        next_state = FR;
            end


            DL: begin
                if (!ground)          next_state = FL;
                else                  next_state = DL;
            end

            DR: begin
                if (!ground)          next_state = FR;
                else                  next_state = DR;
            end

            SPLAT: begin
                next_state = SPLAT;
            end 

            default: next_state = WL;
        endcase
    end

     // State register + fall counter
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= WL;
        end else begin
            state <= next_state;
        end
    end




    /*
        need to work on: 
        -----------------------------------
        DL(4) -> FL(2)
        fall_count_left incrementing properly

        DR(5) -> FR(3)
        fall_count_right not incrementing properly

    */
    always @(posedge clk ) begin
            if (state == FL) 
                fall_count_left <= fall_count_left + 1'b1;
            else if (state == FR)
                fall_count_right <= fall_count_right + 1'b1;
            else 
                fall_count_left <= 0;  
                fall_count_right <= 0;
    end



    // Output logic
    always @(*) begin
        walk_left  = 0;
        walk_right = 0;
        aaah       = 0;
        digging    = 0;

        case (state)
            WL: walk_left  = 1;
            WR: walk_right = 1;
            FL: aaah       = 1;
            FR: aaah       = 1;
            DL: digging    = 1;
            DR: digging    = 1;
            SPLAT: begin
                walk_left  = 0; 
                walk_right = 0;
                aaah       = 0;
                digging    = 0;
            end
        endcase
    end

endmodule
