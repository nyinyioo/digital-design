module top_module (
    input too_cold,
    input too_hot,
    input mode,
    input fan_on,
    output heater,
    output aircon,
    output fan
); 
    assign fan = (fan_on == 1 || (mode == 1 && too_cold == 1) || (mode == 0 && too_hot == 1))  ? 1:0;
    assign heater = (mode == 1 && too_cold == 1) ? 1:0;
    assign aircon = (mode == 0 && too_hot == 1) ? 1:0;
    

endmodule
