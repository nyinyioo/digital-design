///////////////////////////////////////////////////////////////////////////////
// Description:
//     Draws a Reuleaux triangle on a 160x120 VGA grid.
//     Given center (cx, cy) and diameter, computes the three arc centers
//     c1, c2, c3 using fixed-point approximations for sqrt(3)/2.
//
//     Each arc is drawn by the circle module using
//     the inputs c1(x,y) and (radius = diameter).
//     Half-plane tests F12, F23, F31 clip each arc to
//     form the Reuleaux triangle.
//
///////////////////////////////////////////////////////////////////////////////

module reuleaux(input logic clk, input logic rst_n, input logic [2:0] colour,
                input logic [7:0] centre_x, input logic [6:0] centre_y, input logic [7:0] diameter,
                input logic start, output logic done,
                output logic [7:0] vga_x, output logic [6:0] vga_y,
                output logic [2:0] vga_colour, output logic vga_plot);

    //---------------------------------
    // state assignments
    // --------------------------------
    
    typedef enum logic[2:0] {
        CLEAR = 3'd0,
        WAIT = 3'd1,
        DRAW_C3 = 3'd2,
        DRAW_C1 = 3'd3,
        DRAW_C2 = 3'd4,
        DONE = 3'd5
    } state_t;
    state_t state, next_state;

    //---------------------------------
    // internal signals
    // --------------------------------

    // a. corner coordinates
    logic [7:0] c1_x, c2_x, c3_x;
    logic [6:0] c1_y, c2_y, c3_y;

    // b. circle parameters
    logic circle_start, circle_done;
    logic [7:0] circle_centre_x;
    logic [6:0] circle_centre_y;
    logic [2:0] circle_colour;
    logic [7:0] circle_vga_x;
    logic [6:0] circle_vga_y;
    logic circle_vga_plot;

    // c. count
    logic [7:0] x_count;
    logic [6:0] y_count;
    logic pixel_done;

    // d. signed coordinates (overflow)
    logic signed [9:0]  px, py;
    logic signed [9:0]  dx12, dy12;
    logic signed [9:0]  dx23, dy23;
    logic signed [9:0]  dx31, dy31;
    // 20-bit F: product of two 10-bit values
    logic signed [19:0] F12, F23, F31;

    //---------------------------------
    // instantiate circle module
    // --------------------------------

    circle CIRCLE(
        .clk(clk),
        .rst_n(rst_n),
        .colour(colour),
        .centre_x(circle_centre_x),
        .centre_y(circle_centre_y),
        // radius = diameter for the reuleaux triangle
        .radius(diameter),
        .start(circle_start),
        .done(circle_done),
        .vga_x(circle_vga_x),
        .vga_y(circle_vga_y),
        .vga_colour(circle_colour),
        .vga_plot(circle_vga_plot)
    );

    //---------------------------------
    // helper functions
    // --------------------------------

    task automatic counter;
        if (pixel_done) begin
            x_count <= 8'd0; 
            y_count <= 7'd0;
        end else if (y_count == 7'd119) begin
            y_count <= 7'd0;
            x_count <= x_count + 1;
        end else begin
            y_count <= y_count + 1;
        end
    endtask

    always_comb begin
        // calculate c1, c2, c3 coordinates
        c1_x = centre_x + (diameter >> 1);
        c2_x = centre_x - (diameter >> 1);
        c3_x = centre_x;
        c1_y = centre_y + ((diameter * 37) >> 7);
        c2_y = centre_y + ((diameter * 37) >> 7);
        c3_y = centre_y - ((diameter * 37) >> 6);

        // calculate the line difference
        dx12 = $signed({2'b00, c2_x}) - $signed({2'b00, c1_x});
        dy12 = $signed({3'b000, c2_y}) - $signed({3'b000, c1_y});
        dx23 = $signed({2'b00, c3_x}) - $signed({2'b00, c2_x});
        dy23 = $signed({3'b000, c3_y}) - $signed({3'b000, c2_y});
        dx31 = $signed({2'b00, c1_x}) - $signed({2'b00, c3_x});
        dy31 = $signed({3'b000, c1_y}) - $signed({3'b000, c3_y});

    end

    // circle centre mux
    always_comb begin
        circle_centre_x = c3_x;
        circle_centre_y = c3_y;
        circle_start    = 1'b0;

        case(state)
            DRAW_C3: begin
                circle_centre_x = c3_x;
                circle_centre_y = c3_y;
                circle_start    = ~circle_done;
            end
            DRAW_C1: begin
                circle_centre_x = c1_x;
                circle_centre_y = c1_y;
                circle_start    = ~circle_done;
            end
            DRAW_C2: begin
                circle_centre_x = c2_x;
                circle_centre_y = c2_y;
                circle_start    = ~circle_done;
            end
        endcase
    end

    //---------------------------------
    // FSM logic
    // --------------------------------

    // INPUT CL BLOCK
    always_comb begin
        next_state = CLEAR;
        case(state)
            CLEAR:   next_state = (pixel_done)  ? WAIT    : CLEAR;
            WAIT:    next_state = (start)       ? DRAW_C3 : WAIT;
            DRAW_C3: next_state = (circle_done) ? DRAW_C1 : DRAW_C3;
            DRAW_C1: next_state = (circle_done) ? DRAW_C2 : DRAW_C1;
            DRAW_C2: next_state = (circle_done) ? DONE    : DRAW_C2;
            DONE:    next_state = (~start)      ? WAIT    : DONE;
        endcase
    end

    // SEQUENTIAL NS LOGIC
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            state   <= CLEAR;
            x_count <= 8'd0;
            y_count <= 7'd0;
        end else begin
            state <= next_state;
            case(state)
                CLEAR: counter();
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
        vga_colour = 3'b000;
        px         = 10'sd0;
        py         = 10'sd0;
        F12        = 20'sd0;
        F23        = 20'sd0;
        F31        = 20'sd0;

        case(state)
            CLEAR: begin
                vga_x      = x_count;
                vga_y      = y_count;
                vga_plot   = 1'b1;
                vga_colour = 3'b000;
            end

            DRAW_C3: begin
                px = $signed({2'b00,  circle_vga_x});
                py = $signed({3'b000, circle_vga_y});

                vga_x      = circle_vga_x;
                vga_y      = circle_vga_y;
                vga_colour = circle_colour;

                F12     = 20'(dy12*(px-$signed({2'b00,c1_x})) - dx12*(py-$signed({3'b000,c1_y})));

                vga_plot = circle_vga_plot && (F12 >= 0);
            end

            DRAW_C1: begin
                px = $signed({2'b00,  circle_vga_x});
                py = $signed({3'b000, circle_vga_y});

                vga_x      = circle_vga_x;
                vga_y      = circle_vga_y;
                vga_colour = circle_colour;

                F23     = 20'(dy23*(px-$signed({2'b00,c2_x})) - dx23*(py-$signed({3'b000,c2_y})));

                vga_plot = circle_vga_plot && (F23 >= 0);
            end

            DRAW_C2: begin
                px = $signed({2'b00,  circle_vga_x});
                py = $signed({3'b000, circle_vga_y});

                vga_x      = circle_vga_x;
                vga_y      = circle_vga_y;
                vga_colour = circle_colour;

                F31     = 20'(dy31*(px-$signed({2'b00,c3_x})) - dx31*(py-$signed({3'b000,c3_y})));

                vga_plot = circle_vga_plot && (F31 >= 0);
            end

            DONE: begin
                done = 1'b1;
            end
        endcase
    end

    // ASSIGNS
    assign pixel_done = (x_count == 8'd159) && (y_count == 7'd119);

endmodule