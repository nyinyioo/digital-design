module top_module(
    input clk,
    input areset,  // async active-high reset to zero
    input load,
    input ena,
    input [3:0] data,
    output reg [3:0] q); 

    /*
        LSL
        ---------------------
        [q3] [q2] [q1] [q0]
        [0 ] [q3] [q2] [q1]
    */
    
    always @(posedge clk or posedge areset) begin
        if(areset) begin
            q<= 4'b0;
        end else if (load) begin
            q <= data;
        end else begin
            if (ena) begin
                for (int i=1; i<4; i= i+1) begin
                     q[i-1] = q[i];
                end
                q[3] <= 1'b0;
            end
            /*
            //method 2:concatenation
            if(ena) begin
                q<= {1'b0, q[3:1]};
            end
            */
        end
    end



endmodule
