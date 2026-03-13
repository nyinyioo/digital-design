module top_module(
    input clk,
    input load,
    input [255:0] data,
    output [255:0] q ); 

    logic [255:0] next_q;
    integer r, c;

    // count neighbors helper
    function automatic int count_neighbors(input logic [255:0] grid, input int row, input int col);
        int dr, dc;
        int rr, cc;
        int count;
        begin
            count = 0;
            for (dr = -1; dr <= 1; dr = dr + 1) begin
                for (dc = -1; dc <= 1; dc = dc + 1) begin
                    if (!(dr == 0 && dc == 0)) begin
                        rr = (row + dr + 16) % 16;
                        cc = (col + dc + 16) % 16;
                        count = count + grid[rr*16 + cc];
                    end
                end
            end
            count_neighbors = count;
        end
    endfunction

    //CL BLOCK
    always @(*) begin
        for (r = 0; r < 16; r = r + 1) begin
            for (c = 0; c < 16; c = c + 1) begin
                int n;
                n = count_neighbors(q, r, c);

                case (n)
                    2: next_q[r*16 + c] = q[r*16 + c]; // stays the same
                    3: next_q[r*16 + c] = 1'b1;        // becomes alive
                    default: next_q[r*16 + c] = 1'b0;  // dies
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= next_q;
    end

endmodule
