module top_module (
    input clk,
    input j,
    input k,
    output Q); 


/*
    J  K    Q
    -----------
    0  0   Qold 
    0  1    0
    1  0    1
    1  1  ~Qold

            _____
        |     |
    -ns-|D   Q|-s-
        |_____|


    s,ns truthtable
    ------------------
    | J | K | S | NS |
    | - | - | - | -- |
    | 0 | 0 | 0 | 0  |
    | 0 | 0 | 1 | 1  |
    | 0 | 1 | 0 | 0  |
    | 0 | 1 | 1 | 0  |
    | 1 | 0 | 0 | 1  |
    | 1 | 0 | 1 | 1  |
    | 1 | 1 | 0 | 1  |
    | 1 | 1 | 1 | 0  |


    kmap for nextstate
    -------------------
    | J \ KS | 00 | 01 | 11 | 10 |
    | ------ | -- | -- | -- | -- |
    |    0   | 0  | 1  | 0  | 0  |
    |    1   | 1  | 1  | 0  | 1  |

    boolean eq
    -------------------
    ns = (J & ~S) || (~K & S)

*/


    reg s,ns;

    //input CL block
    always_comb begin
        ns = (j & ~s) || (~k & s);
    end

    //state transition
    always@(posedge clk) begin
        s<=ns;
    end

    //output CL block
    assign Q = s;

endmodule