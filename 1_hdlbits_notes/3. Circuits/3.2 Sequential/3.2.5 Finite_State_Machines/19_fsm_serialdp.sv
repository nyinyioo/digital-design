module top_module(
    input clk,
    input in,
    input reset,
    output [7:0] out_byte,
    output done
);
    
    //declare signals
    integer i;
    parameter WAIT=3'd0, START=3'd1, DATA=3'd2, PARITY=3'd3, STOP=3'd4, ERR=3'd5;
    logic [2:0] state, next_state;
    logic [3:0] count;
    logic [7:0] out_byte_r;
    logic done_r;
    wire odd, rst;

    //check parity
    assign rst = reset || (next_state == START);
    parity parity_inst ( 
        .clk(clk), 
        .reset(rst), 
        .in(in), 
        .odd(odd)
    );

    // input CL logic
    always_comb begin
        case(state)
            WAIT: begin 
                next_state = in ? WAIT : START;
            end 
            START: begin 
                next_state = DATA;
            end
            DATA: begin 
                next_state = (count == 4'd8) ? PARITY : DATA;
            end 
            PARITY: begin 
                next_state = in ? STOP : ERR;
            end 
            STOP: begin 
                next_state = in ? WAIT : START;
            end 
            ERR: begin
                next_state = in ? WAIT : ERR;
            end 
            default: next_state = WAIT;
        endcase
    end

    // sequential logic 
    always_ff @(posedge clk) begin
        if (reset) begin 
            state <= WAIT;
        end 
        else begin 
            state <= next_state;
        end 
    end

    // dp: count and bit capture 
    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 4'd0;
            i <= 0;
            out_byte_r <= 8'd0;
        end else begin
            case (next_state)
                START: begin
                    count <= 4'd0;
                    i <= 0;
                    out_byte_r <= 8'd0;
                end
                DATA: begin
                    count <= count + 4'd1;
                    out_byte_r[i] <= in;
                    i <= i + 1;
                end
                STOP: begin
                    // Hold out_byte_r
                end
                default: begin
                    count <= 4'd0;
                    i <= 0;
                end
            endcase
        end
    end

    // Done signal
    // asserted in STOP state when parity is correct
    always_ff @(posedge clk) begin
        if (reset) begin
            done_r <= 1'b0;
        end else begin
            case (next_state)
                STOP: done_r <= odd;
                default: done_r <= 1'b0;
            endcase
        end
    end
    
    assign done = done_r;
    assign out_byte = out_byte_r;
    
endmodule