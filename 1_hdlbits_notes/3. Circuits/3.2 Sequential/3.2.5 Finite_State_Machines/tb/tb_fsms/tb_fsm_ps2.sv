
`timescale 1ns/1ns
module tb_fsm_p2s();
    //declare intermediate signals
    logic clk;
    logic [7:0] in;
    logic reset;
    logic [1:0] state, next_state; 
    logic [23:0] message;
    wire done;

    //initialize DUT
    fsm DUT (clk, in, reset, done);

    //probe internal signals
    assign message = DUT.message;
    assign state = DUT.state;
    assign next_state = DUT.next_state;


    //clock generation
    always #5 clk = ~clk; 


    /* 
        100 % functional coverage
        a. visit all states 
        b. cover all paths

        review timing 
    
    */
     initial begin
        /*
        state: s0 -> s1  
            a. ( bit[3] != 1 )
            b. ( bit[3] == 1 )
        */

        //initialize signals
        clk = 0;
        reset = 1'b1;
        in = 8'b00000000;
        #10;
        reset = 1'b0;
        #5;
        

       //case a: ( bit[3] != 1 )
        in = 8'b11110111; #10; 
        //display ~ message is loaded with first byte and we are in s0.
        #1;
        assert (DUT.message[7:0] != in) else $error("Testcase s0-a Failed: Expected message[7:0] == 8'b00000000 & in = 8'b1110111, Got message[7:0] == %b, in = %b", DUT.message[7:0], in);
        assert(DUT.state == 2'b00) else $error("Testcase s0-a Failed: Expected State is s0, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b00) else $error("Testcase s0-a Failed: Expected Next State is s0, Got Next State = %b", DUT.next_state);

       //case b: ( bit[3] == 1 )
        in = 8'b11111111; #10; 
        #1;
        //display ~ message is loaded with first byte and we are in s0.
        assert(DUT.message[7:0] == in) else $error("Testcase s0-b Failed: Expected message[7:0] == 8'b1111111 & in = 8'b1111111, Got message[7:0] == %b, in = %b", DUT.message[7:0], in);
        assert(DUT.state == 2'b01) else $error("Testcase s0-b Failed: Expected State is s1, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b10) else $error("Testcase s0-b Failed: Expected Next State is s2, Got Next State = %b", DUT.next_state);
        assert(DUT.done == 1'b0) else $error("Testcase s1 Failed: Expected done = 1'b0, Got done = %b", DUT.done);

        /*
            state: s1 -> s2  
                a. load 2nd byte bit[3] = X

        */
        in = 8'b10101010; #10;
        #1; 
        assert(DUT.message[15:8] == in) else $error("Testcase s1 Failed: Expected message[15:8] == 8'b10101010 & in = 8'b10101010, Got message[15:8] == %b, in = %b", DUT.message[15:8], in);
        assert(DUT.state == 2'b10) else $error("Testcase s1 Failed: Expected State is s2, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b11) else $error("Testcase s1 Failed: Expected Next State is s3, Got Next State = %b", DUT.next_state);
        assert(DUT.done == 1'b0) else $error("Testcase s1 Failed: Expected done = 1'b0, Got done = %b", DUT.done);

        /*
            state: s2 -> s3  
                a. load 3rd byte bit[3] = X

        */
        in = 8'b01011101; #10; 
        #1;
        assert (DUT.message[23:16] == in) else $error("Testcase s2 Failed: Expected message[23:16] == 8'b01011101 & in = 8'b01011101, Got message[23:16] == %b, in = %b", DUT.message[23:16], in);
        assert(DUT.state == 2'b11) else $error("Testcase s2 Failed: Expected State is s3, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b00) else $error("Testcase s2 Failed: Expected Next State is s0, Got Next State = %b", DUT.next_state);
        assert(DUT.done == 1'b1) else $error("Testcase s2 Failed: Expected done = 1'b1, Got done = %b", DUT.done);


      /*
        state: s3 -> s0  
            a. ( bit[3] != 1 )
            b. ( bit[3] == 1 )

        */
   
       //case a: ( bit[3] != 1 )
        in = 8'b11110111; #10; 
        //display ~ message is loaded with first byte and we are in s0.
        #1;
        assert(DUT.message[7:0] != in) else $error("Testcase s3-a Failed: Expected message[7:0] == 8'b00000000 & in = 8'b1110111, Got message[7:0] == %b, in = %b", DUT.message[7:0], in);
        assert(DUT.state == 2'b00) else $error("Testcase s3-a Failed: Expected State is s0, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b00) else $error("Testcase s3-a Failed: Expected Next State is s0, Got Next State = %b", DUT.next_state);

       //case b: ( bit[3] == 1 )
        in = 8'b11111111; #10; 
        #1;
        //display ~ message is loaded with first byte and we are in s0.
        assert(DUT.message[7:0] == in) else $error("Testcase s3-b Failed: Expected message[7:0] == 8'b1111111 & in = 8'b1111111, Got message[7:0] == %b, in = %b", DUT.message[7:0], in);
        assert(DUT.state == 2'b01) else $error("Testcase s3-b Failed: Expected State is s1, Got State = %b", DUT.state);
        assert(DUT.next_state == 2'b10) else $error("Testcase s3-b Failed: Expected Next State is s2, Got Next State = %b", DUT.next_state);
        assert(DUT.done == 1'b0) else $error("Testcase s3-b Failed: Expected done = 1'b0, Got done = %b", DUT.done);


        //reset to s0
        reset = 1'b1; #5;
        reset = 1'b0; #10;

        
        #1;
        assert (DUT.message == 24'b000000001111111111111111 ) else $error("Testcase 1 Failed: Expected message == 24'b0, Got message == %b", DUT.message);
        assert (DUT.state == 2'b01) else $error("Testcase 1 Failed: Expected State is s1, Got State = %b", DUT.state);


        $display("All Testcases Passed!");
        $stop;

     end
endmodule