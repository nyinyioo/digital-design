module statemachine(input logic slow_clock, input logic resetb,
                    input logic [3:0] dscore, input logic [3:0] pscore, input logic [3:0] pcard3,
                    output logic load_pcard1, output logic load_pcard2, output logic load_pcard3,
                    output logic load_dcard1, output logic load_dcard2, output logic load_dcard3,
                    output logic player_win_light, output logic dealer_win_light);

    
    parameter 
            START = 5'd0,         // Deal P1
            S0 = 5'd1,            // Deal D1
            S1 = 5'd2,            // Deal P2
            S2 = 5'd3,            // Deal D2
            CHECK_NAT = 5'd4,     // Check natural after 4 cards

            DEAL_P3 = 5'd5,       // Deal P3 (if player draws)
            DECIDE_D3 = 5'd6,     // Decide if dealer draws based on dscore + pcard3_value
            DEAL_D3 = 5'd7,       // Deal D3 (if dealer draws)

            CHECK_SCORE = 5'd8,   // Compare final scores

            PLAYER_WINS = 5'd9,   // Hold winner lights until reset
            DEALER_WINS = 5'd10,
            TIE = 5'd11;

    // State registers
    logic [4:0] state, next_state;
    
    // Intermediate signals 
    logic natural;
    logic player_gets_card3;
    logic dealer_gets_card3;
    
    // Baccarat value of player's 3rd card 
    logic [3:0] pcard3_value; 

    //CL B1: intermediate signals
    always_comb begin
        // Natural: either player or dealer has 8 or 9
        natural = (pscore == 4'd8 || pscore == 4'd9 || dscore == 4'd8 || dscore == 4'd9);

        // Player_gets_card3 if pscore from card1+card2 is 0-5 (player stands on 6 or 7)
        player_gets_card3 = (pscore <= 4'd5);

        // convert card 3 to baccarat value
        if (pcard3 >= 4'd1 && pcard3 <= 4'd9) 
            pcard3_value = pcard3; 
        else 
            pcard3_value = 4'd0; // this is for the 10+ case 
        
        // default 
        dealer_gets_card3 = 1'b0; 

        // Dealer draw rule depends on whether player drew a 3rd card this should only be used 
        // after pcard3 has actually been dealt
        if (player_gets_card3) begin
            // so player drew a third card so baker rules depend on the pcard3_value

            case (dscore)
                //gets card if dscore is between 0-2
                4'd0, 4'd1, 4'd2: dealer_gets_card3 = 1'b1;  

                //pcard3 ~8; So draws unless players 3rd card is 8
                4'd3: dealer_gets_card3 = (pcard3_value != 4'd8); 

                // pcard3 is between 2-7
                4'd4: dealer_gets_card3 = (pcard3_value >= 4'd2 && pcard3_value <= 4'd7); 

                // pcard3 is between 4-7
                4'd5: dealer_gets_card3 = (pcard3_value >= 4'd4 && pcard3_value <= 4'd7);  

                // pcard3 is between 6-7
                4'd6: dealer_gets_card3 = (pcard3_value == 4'd6 || pcard3_value == 4'd7);  

                // does not get a card if dscore = 7
                4'd7: dealer_gets_card3 = 1'b0;  

                default: dealer_gets_card3 = 1'b0;
            endcase

        //~player_gets_card3: player's score from card1+card2 is 6 or 7, 
        end else begin

            //Dealer_gets_card3 if dscore from card1+card2 is 0-5
            dealer_gets_card3 = (dscore <= 4'd5);
        end
    end
    

    //CL B2: next_state logic
    always_comb begin
        case (state)
            // first four cards are automatic 
            START: next_state = S0;           // load_pcard1
            S0: next_state = S1;              // load_dcard1
            S1: next_state = S2;              // load_pcard2
            S2: next_state = CHECK_NAT;       // load_dcard2 then check for naturals 
            
            // After 4 cards, decide natural case
            CHECK_NAT: begin 
                if (natural) 
                    next_state = CHECK_SCORE; // game ends immediately 
                else if (player_gets_card3)
                    next_state = DEAL_P3;     // must deal pcard3 first 
                else if (!player_gets_card3 && dealer_gets_card3)
                    next_state = DEAL_D3;     // player stands here dealer may draw
                else 
                    next_state = CHECK_SCORE; // neither of the two draws a 3rd card and we go to check score 
            end 

            // Deal players 3rd card, then decide dealer based on newly loaded pcard3 
            DEAL_P3: next_state = DECIDE_D3;

            DECIDE_D3: begin 
                if (dealer_gets_card3) 
                    next_state = DEAL_D3; 
                else
                    next_state = CHECK_SCORE;
            end 

            // Dealer draws 3rd card, then finish 
            DEAL_D3: next_state = CHECK_SCORE;

            // Compare final scores 
            CHECK_SCORE: begin
                if (pscore > dscore)
                    next_state = PLAYER_WINS;
                else if (dscore > pscore)
                    next_state = DEALER_WINS;
                else
                    next_state = TIE;
            end

            // Terminal states should honld (spin) until reset is asserted 
            PLAYER_WINS: next_state = PLAYER_WINS;
            DEALER_WINS: next_state = DEALER_WINS;
            TIE: next_state = TIE;

            default: next_state = START;
        endcase
    end
    
    
    //Sequential Block: active low
    always_ff @(posedge slow_clock) begin
        if (!resetb)  
            state <= START;
        else
            state <= next_state;
    end
    

    // CL B3: output logic 
    // (Moore machine - outputs depend only on state)
    always_comb begin
        // default: all outputs off
        load_pcard1 = 1'b0;
        load_pcard2 = 1'b0;
        load_pcard3 = 1'b0;
        load_dcard1 = 1'b0;
        load_dcard2 = 1'b0;
        load_dcard3 = 1'b0;
        player_win_light = 1'b0;
        dealer_win_light = 1'b0;
        
        case (state)
            START: load_pcard1 = 1'b1;
            S0: load_dcard1 = 1'b1;
            S1: load_pcard2 = 1'b1;
            S2: load_dcard2 = 1'b1;
            DEAL_P3: load_pcard3 = 1'b1;  
            DEAL_D3: load_dcard3 = 1'b1;  
            
            PLAYER_WINS: player_win_light = 1'b1;
            DEALER_WINS: dealer_win_light = 1'b1;

            TIE: begin
                player_win_light = 1'b1;
                dealer_win_light = 1'b1;
            end

        endcase
    end

endmodule