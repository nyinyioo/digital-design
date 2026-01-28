module top_module(
    input clk,
    input load,
    input ena,
    input [1:0] amount,
    input [63:0] data,
    output reg [63:0] q); 


    parameter N =  63;
    parameter M = 8;

    /*

        If you are shifting → use <<, >>, >>>
        If you are rotating → use concatenation

        N = Length of Vector
        M = Rotate or Shift amnount

        Rotate Right
        ---------------------
        [q3] [q2] [q1] [q0]  
        [q0 ] [q3] [q2] [q1]
        [q1 ] [q0] [q3] [q2]
        [q2 ] [q1] [q0] [q3]

         m = 1, n =3
        [q0 ] [q3] [q2] [q1]

        m = 2 , n = 3
        [q1 ] [q0] [q3] [q2]

        m = 3 , n = 3
        [q2 ] [q1] [q0] [q3]
    

        ==> { q[m-1:0], q[n:m] }
  

        Rotate Left
        ---------------------
        [q3] [q2] [q1] [q0]  
        [q2] [q1] [q0] [q3]
        [q1 ] [q0] [q3] [q2]
        [q0 ] [q3] [q2] [q1]

         m = 1, n =3
        [q2] [q1] [q0] [q3]

        m = 2 , n = 3
        [q1 ] [q0] [q3] [q2]

        m = 3 , n = 3
       [q0 ] [q3] [q2] [q1]
    

        ==> { q[n-m:0], q[n:n-m+1] }




        Arithmetic Shift Right 
        -----------------------
        [q3] [q2] [q1] [q0] 

        by one:  [q3] [q3] [q2] [q1] 
        by two:  [q3] [q3] [q3] [q2] 

        divison by 2 

        $signed(q) >>> m; 


        Shift Left 
        -----------------------
        [q3] [q2] [q1] [q0] 

        by one:  [q3] [q1] [q0] [0] 
        by two:  [q3] [q0] [0] [0] 

        multiplication by 2 

        q << m
    */


    always @(posedge clk ) begin
     if (load) begin
            q <= data;
        end else if (ena) begin
                case (amount)
                    2'b00: q <= q << 1;              // left by 1
                    2'b01: q <= q << 8;              // left by 8
                    2'b10: q <= $signed(q) >>> 1;    // arithmetic right by 1
                    2'b11: q <= $signed(q) >>> 8;    // arithmetic right by 8
                endcase
            end
    end
endmodule


