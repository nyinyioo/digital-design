module top_module(
    input clk,
    input in,
    input reset,
    output done
); 
    //state assignment
    typedef enum logic [1:0] { 
        WAIT = 2'd1,
        DATA = 2'd2,
        STOP = 2'd3,
        ERR  = 2'd4

    } state_t;
    state_t state, next_state;

    //assign internal wires
    logic [3:0] count;
    logic [7:0] out_byte_r;
    integer i;

    // Next-state logic
    always_comb begin
        unique case(state)
            WAIT: begin 
                next_state = in ? WAIT : DATA;
            end 
            DATA: begin 
                next_state = (count < 4'd8) ? DATA : (in ? STOP : ERR);
            end
            STOP: begin 
                next_state = in ? WAIT : DATA;
            end 
            ERR:  begin 
                next_state = in ? WAIT : ERR;
            end 
            default: next_state = WAIT;
        endcase
    end

    // State register
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= WAIT;
        end else begin
            state <= next_state;
        end
    end

    // Datapath: count and bit capture
    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 4'd0;
            i <= 0;
            out_byte_r <= 8'd0;
        end else if (state == DATA) begin
            out_byte_r[i] <= in;
            i <= i + 1;
            count <= count + 4'd1;
        end
        else begin
            count <= 4'd0;
            i <= 0;
        end
    end

    assign done = (state == STOP);

endmodule