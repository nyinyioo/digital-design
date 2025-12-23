// synthesis verilog_input_version verilog_2001
module top_module (
    input [15:0] scancode,
    output reg left,
    output reg down,
    output reg right,
    output reg up  ); 

/*
every output must be assigned a value, otherwise it creates latches CL rules, default case.
note: need to define default values above, as only one of outputs can be high.
*/

    always@(*) begin
        up = 1'b0; down = 1'b0; left = 1'b0; right = 1'b0;
        case(scancode)
            16'he06b: left = 1;  
            16'he072: down = 1;  
            16'he074: right = 1; 
            16'he075: up = 1;     
            default: begin
                left = 0;
                down = 0;
                right = 0;
                up = 0;
            end
        endcase
    end 
endmodule