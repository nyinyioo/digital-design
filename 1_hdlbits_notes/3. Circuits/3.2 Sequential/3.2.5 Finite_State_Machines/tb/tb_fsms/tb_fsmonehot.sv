module tb_onehot ();

    //initialize signals
    logic in;
    logic [9:0] state;
    wire [9:0] next_state;
    wire out1, out2;

    //instantiate UUT
    onehot UUT(in, state, next_state, out1, out2);

    initial begin
        /*     
            S0 -> [0] -> S0 ->  [1] -> S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [0] ->  S8
            S8 -> [0] -> S0 -> [1] ->  S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [1] -> S6 -> [0] -> S9 
            S9 -> [0] -> S0 -> [1] ->  S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [1] -> S6 -> [1] -> S7 
            S7 -> [1] -> S7 -> [0] ->  S0 
        */   

        // Initialize to S0
        state = 10'b0000000001;
        #5;

        // PATH1: S0 -> [0] -> S0 ->  [1] -> S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [0] ->  S8
        in = 0; #5;  
        assert (next_state == 10'b0000000001) else $error("S0 with in=0 should go to S0");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000010) else $error("S0 with in=1 should go to S1");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000100) else $error("S1 with in=1 should go to S2");
        state = next_state; #5;
        
        in = 1; #5; 
        assert (next_state == 10'b0000001000) else $error("S2 with in=1 should go to S3");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000010000) else $error("S3 with in=1 should go to S4");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000100000) else $error("S4 with in=1 should go to S5");
        state = next_state; #5;
        
        in = 0; #5;
        assert (next_state == 10'b0100000000) else $error("S5 with in=0 should go to S8");
        state = next_state; #5;

        // PATH 2: S8 -> [0] -> S0 -> [1] ->  S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [1] -> S6 -> [0] -> S9 
        in = 0; #5;  
        assert (next_state == 10'b0000000001) else $error("S8 with in=0 should go to S0");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000010) else $error("S0 with in=1 should go to S1");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000100) else $error("S1 with in=1 should go to S2");
        state = next_state; #5;
        
        in = 1; #5; 
        assert (next_state == 10'b0000001000) else $error("S2 with in=1 should go to S3");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000010000) else $error("S3 with in=1 should go to S4");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000100000) else $error("S4 with in=1 should go to S5");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0001000000) else $error("S5 with in=1 should go to S6");
        state = next_state; #5;
        
        in = 0; #5;
        assert (next_state == 10'b1000000000) else $error("S6 with in=0 should go to S9");
        state = next_state; #5;

        // PATH 3: S9 -> [0] -> S0 -> [1] ->  S1 -> [1] ->  S2 -> [1] ->  S3 -> [1] ->  S4 -> [1] ->  S5 -> [1] -> S6 -> [1] -> S7 
        in = 0; #5;  
        assert (next_state == 10'b0000000001) else $error("S9 with in=0 should go to S0");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000010) else $error("S0 with in=1 should go to S1");
        state = next_state; #5;
        
        in = 1; #5;  
        assert (next_state == 10'b0000000100) else $error("S1 with in=1 should go to S2");
        state = next_state; #5;
        
        in = 1; #5; 
        assert (next_state == 10'b0000001000) else $error("S2 with in=1 should go to S3");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000010000) else $error("S3 with in=1 should go to S4");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0000100000) else $error("S4 with in=1 should go to S5");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0001000000) else $error("S5 with in=1 should go to S6");
        state = next_state; #5;
        
        in = 1; #5;
        assert (next_state == 10'b0010000000) else $error("S6 with in=1 should go to S7");
        state = next_state; #5;

        // PATH 4: S7 -> [1] -> S7 -> [0] ->  S0
        in = 1; #5;  
        assert (next_state == 10'b0010000000) else $error("S7 with in=1 should go to S7");
        state = next_state; #5;
        
        in = 0; #5;  
        assert (next_state == 10'b0000000001) else $error("S7 with in=0 should go to S0");
        state = next_state; #5;

        $display("All tests passed!");
        $finish;
    end
endmodule