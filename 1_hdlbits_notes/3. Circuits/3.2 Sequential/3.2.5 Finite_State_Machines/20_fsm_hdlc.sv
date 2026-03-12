module top_module(
    input clk,
    input reset,
    input in,
    output disc,
    output flag,
    output err);

    parameter IDLE=3'd0, START=3'd1, FLAG=3'd2, DISC=3'd3, ERR=3'd4;
    logic [2:0] state, next_state;
    logic [2:0] count, next_count;

    always_comb begin
        next_state = state;
        next_count = count;
        case(state)
            IDLE: begin
                if (in) begin
                    next_state = START;
                    next_count = 3'd1;
                end else begin
                    next_state = IDLE;
                    next_count = 3'd0;
                end
            end

            START: begin
                if (in) begin
                    if (count >= 3'd6) begin
                        next_state = ERR;
                        next_count = 3'd0;
                    end else begin
                        next_state = START;
                        next_count = count + 1'b1;
                    end
                end else begin
                    next_count = 3'd0;
                    if      (count == 3'd5) next_state = DISC;
                    else if (count == 3'd6) next_state = FLAG;
                    else                    next_state = IDLE;
                end
            end

            // After DISC/FLAG, immediately continue — in=1 starts new count, in=0 goes idle
            DISC: begin
                next_count = in ? 3'd1 : 3'd0;
                next_state = in ? START : IDLE;
            end

            FLAG: begin
                next_count = in ? 3'd1 : 3'd0;
                next_state = in ? START : IDLE;
            end

            ERR: begin
                next_state = in ? ERR : IDLE;
                next_count = 3'd0;
            end

            default: begin
                next_state = IDLE;
                next_count = 3'd0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            count <= 3'd0;
        end else begin
            state <= next_state;
            count <= next_count;
        end
    end

    assign disc = (state == DISC);
    assign flag = (state == FLAG);
    assign err  = (state == ERR);

endmodule