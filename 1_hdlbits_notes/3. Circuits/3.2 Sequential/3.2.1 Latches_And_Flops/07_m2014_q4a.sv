module top_module (
    input d, 
    input ena,
    output q);

    /*

        Latches are level-sensitive (not edge-sensitive) circuits,
        so in an always block, they use level-sensitive sensitivity lists.

        A D-latch acts like a wire (or non-inverting buffer) when enabled,
        and preserves the current value when disabled.

        Sequential Elements: Use Non-Blocking Elements
        
   */

    always@(*) begin
        if (ena) begin
            q<=d;
        end 
    end

endmodule
