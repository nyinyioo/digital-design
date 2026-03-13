module top_module( input in, output out );
    always @ (in) begin
		out = ~ in;
    end
endmodule