module spi_controller (
    input  logic clk,        // 50MHz
    input  logic rst_n,      // active low reset

    // user interface
    input  logic [7:0] data, // byte to send
    input  logic       dc,   // 0=command, 1=data
    input  logic       send, // pulse high to send
    output logic       ready,// high when idle

    // ST7789 pins → GPIO_0
    output logic SPI_CLK,    // IO_A0  PIN[1]
    output logic SPI_MOSI,   // IO_A2  PIN[3]
    output logic SPI_CS,     // IO_A4  PIN[5]
    output logic SPI_DC,     // IO_A3  PIN[4]
    output logic SPI_RST,    // IO_A1  PIN[2]
    output logic SPI_BL      // IO_A13 PIN[16]
);

    // SPI clock divider
    // 50MHz / 4 = 12.5MHz SPI clock (within ST7789 spec)
    logic [1:0] clk_div;
    logic       spi_clk_en;  // pulse when SPI clock should toggle

    // shift register
    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;     // counts 0-7
    logic       busy;

    typedef enum logic [1:0] {
        IDLE    = 2'd0,
        TRANSFER = 2'd1,
        DONE    = 2'd2
    } state_t;

    state_t state, next_state;

    // clock divider — generates SPI clock enable
    always_ff @(posedge clk) begin
        if(!rst_n) clk_div <= 2'd0;
        else       clk_div <= clk_div + 2'd1;
    end
    assign spi_clk_en = (clk_div == 2'd3); // pulse every 4 cycles

    // next state
    always_comb begin
        next_state = state;
        case(state)
            IDLE:     next_state = send ? TRANSFER : IDLE;
            TRANSFER: next_state = (spi_clk_en && bit_cnt == 3'd7 && SPI_CLK) 
                                   ? DONE : TRANSFER;
            DONE:     next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // sequential
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state     <= IDLE;
            shift_reg <= 8'd0;
            bit_cnt   <= 3'd0;
            SPI_CLK   <= 1'b0;
            SPI_CS    <= 1'b1;  // deasserted
            SPI_DC    <= 1'b0;
            SPI_MOSI  <= 1'b0;
            SPI_BL    <= 1'b1;  // backlight on
            SPI_RST   <= 1'b1;  // not in reset
        end else begin
            state <= next_state;
            unique case(state)
                IDLE: begin
                    SPI_CS  <= 1'b1;
                    SPI_CLK <= 1'b0;
                    if(send) begin
                        shift_reg <= data;
                        SPI_DC    <= dc;
                        SPI_CS    <= 1'b0;  // assert CS
                        bit_cnt   <= 3'd0;
                    end
                end
                TRANSFER: begin
                    if(spi_clk_en) begin
                        SPI_CLK <= ~SPI_CLK;
                        if(!SPI_CLK) begin
                            // falling edge → shift out next bit
                            SPI_MOSI  <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            bit_cnt   <= bit_cnt + 3'd1;
                        end
                    end
                end
                DONE: begin
                    SPI_CS  <= 1'b1;  // deassert CS
                    SPI_CLK <= 1'b0;
                end
            endcase
        end
    end

    assign ready = (state == IDLE);

endmodule
