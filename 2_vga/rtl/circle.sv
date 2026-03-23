///////////////////////////////////////////////////////////////////////////////
// Description:
//     Draws a circle on a 160x120 VGA grid using Bresenham's circle algorithm.
//     Given radius and center (cx, cy), uses decision variable crit
//     to compute pixel coordinates (px, py). An FSM counter plots across 8 octants 
//     by symmetry before advancing to the next pixel.
//
// FSM PARAMETERS: 
//    RESET  → CLEAR  : rst_n 
//    CLEAR  → WAIT   : if pixel_done 
//    WAIT   → PLOT   : if start 
//    PLOT   → DONE   : if pixel_done 
//    DONE   → PLOT   : if start 
//    DONE   → WAIT   : otherwise
///////////////////////////////////////////////////////////////////////////////

module circle(input logic clk, input logic rst_n, input logic [2:0] colour,
              input logic [7:0] centre_x, input logic [6:0] centre_y, input logic [7:0] radius,
              input logic start, output logic done,
              output logic [7:0] vga_x, output logic [6:0] vga_y,
              output logic [2:0] vga_colour, output logic vga_plot);

    //state assignments
    typedef enum logic[1:0] {
        CLEAR = 3'd0,
        WAIT = 3'd1,
        PLOT = 2'd2,
        DONE = 2'd3
    } state_t;

    state_t state, next_state;

    // internal signals
    logic [7:0] x_count, offset_x; 
    logic [6:0] y_count, offset_y;
    logic signed [8:0] crit;
    logic [2:0] octant;
    logic pixel_done, circle_done, octant_done;

    // signed pixel coordinates: need 9 bits to represent range [-128, 127]
    // px = centre_x + offset_x
    // py = centre_y + offset_y
    logic signed [8:0] px, py;

    //---------------------------------
    // helper functions
    // --------------------------------
    // counter updates x_count and y_count for CLEAR state
    task automatic counter;
        if (pixel_done) begin
            x_count <= 8'd0;
            y_count <= 7'd0;
        end 
        else if (y_count == 7'd119) begin
            y_count <= 7'd0;
            x_count <= x_count + 1;
        end 
        else begin
            y_count <= y_count + 1;
        end
    endtask

    // bresenham update for next values of (offset_x and offset_y, decision variable crit)
     task automatic breshenham;
     if (crit <= 0) begin
          crit     <= crit + $signed(9'(2*(offset_y + 1) + 1));
     end else begin
          crit     <= crit + $signed(9'(2*(offset_y + 1 - offset_x) + 1));
          offset_x <= offset_x - 1;
     end
     offset_y <= offset_y + 1;
     octant   <= 3'd0;
     endtask
    
    //---------------------------------
    // FSM logic
    // --------------------------------

    // INPUT CL BLOCK
    always_comb begin
        next_state = CLEAR;
        case(state) 
            CLEAR: begin
                next_state = (pixel_done) ? WAIT : CLEAR;
            end
            WAIT: begin
                next_state = (start) ? PLOT : WAIT;
            end
            PLOT: begin 
                next_state = (~start && ~circle_done) ? WAIT : 
                                        (circle_done) ? DONE : PLOT;
            end
            DONE: begin
                next_state = (~start) ? WAIT : DONE;
            end
        endcase
    end
    
    // SEQUENTIAL NS BLOCK
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            state    <= CLEAR;
            x_count  <= 8'd0;
            y_count  <= 7'd0;
            offset_x <= 8'd0;
            offset_y <= 7'd0;
            crit     <= 9'd0;
            octant   <= 3'd0;

        end else begin
            state <= next_state;

            case(state)
                CLEAR: begin
                    counter();
                end

                WAIT: begin
                    if (start) begin
                        //$display("WAIT: radius=%0d, crit=%0d", radius, 9'sd1 - $signed({1'b0,radius}));
                        offset_x <= radius;
                        offset_y <= 7'd0;
                        crit     <= 9'sd1 - $signed({1'b0, radius});
                        octant   <= 3'd0;
                    end
                end

                PLOT: begin
                    if (octant_done) begin
                        breshenham();
                    end else begin
                        octant <= octant + 1;
                    end
                end

                DONE: begin
                    x_count <= 8'd0;
                    y_count <= 7'd0;
                end
            endcase
        end
    end
    
    // OUTPUT CL BLOCK
    always_comb begin
        done       = 1'b0;
        vga_x      = 8'b0;
        vga_y      = 7'b0;
        vga_plot   = 1'b0;
        vga_colour = 3'b0;
        px         = 9'sd0;
        py         = 9'sd0;

        case(state)
            CLEAR: begin
                vga_x      = x_count;
                vga_y      = y_count;
                vga_plot   = 1'b1;
                vga_colour = 3'b000;
            end
            
            WAIT: begin
            end
            
            PLOT: begin
                vga_colour = colour;
                case(octant)
                    3'd0: begin  //octant 1
                        px = $signed({1'b0, centre_x}) + $signed({1'b0, offset_x}); 
                        py = $signed({1'b0, centre_y}) + $signed({1'b0, offset_y}); 
                    end
                    3'd1: begin  //octant 2
                        px = $signed({1'b0, centre_x}) + $signed({1'b0, offset_y}); 
                        py = $signed({1'b0, centre_y}) + $signed({1'b0, offset_x}); 
                    end
                    3'd2: begin  //octant 3
                        px = $signed({1'b0, centre_x}) - $signed({1'b0, offset_y}); 
                        py = $signed({1'b0, centre_y}) + $signed({1'b0, offset_x}); 
                    end
                    3'd3: begin  //octant 4
                        px = $signed({1'b0, centre_x}) - $signed({1'b0, offset_x}); 
                        py = $signed({1'b0, centre_y}) + $signed({1'b0, offset_y}); 
                    end
                    3'd4: begin  //octant 5
                        px = $signed({1'b0, centre_x}) - $signed({1'b0, offset_x}); 
                        py = $signed({1'b0, centre_y}) - $signed({1'b0, offset_y}); 
                    end
                    3'd5: begin //octant 6
                        px = $signed({1'b0, centre_x}) - $signed({1'b0, offset_y}); 
                        py = $signed({1'b0, centre_y}) - $signed({1'b0, offset_x}); 
                    end
                    3'd6: begin //octant 7
                        px = $signed({1'b0, centre_x}) + $signed({1'b0, offset_y}); 
                        py = $signed({1'b0, centre_y}) - $signed({1'b0, offset_x}); 
                    end
                    3'd7: begin //octant 8
                        px = $signed({1'b0, centre_x}) + $signed({1'b0, offset_x}); 
                        py = $signed({1'b0, centre_y}) - $signed({1'b0, offset_y}); 
                    end
                endcase

                // plot if within bounds (0 <= x < 160, 0 <= y < 120) 
                
                vga_x    = px[7:0];
                vga_y    = py[6:0];
                vga_plot = (px >= 0) && (py >= 0) && 
                           (px < 9'sd160) && (py < 9'sd120);
            end
            
            DONE: begin
                done = 1'b1;
            end
            
        endcase
    end

    // ASSIGNS
    assign pixel_done  = (x_count == 8'd159) && (y_count == 7'd119);
    assign circle_done = (offset_y > offset_x);
    assign octant_done = (octant == 3'd7);

endmodule