module uart(input wire clk,
            input wire rx,
            output reg tx,
);
    //*************************************************************************
    // Might want an enable bit to switch from normal i/o operation to
    // uart mode.

    //*************************************************************************
    // Create sampling clock
    reg [7:0] prescaler = 8'b0;
    reg sample_enable = 1'b0;
    always @(posedge clk) begin
        if(prescaler == 8'd103) begin
            prescaler <= 0;
            sample_enable <= 1;
        end
        else begin
            prescaler <= prescaler + 1;
            sample_enable <= 0;
        end
    end
    //*************************************************************************
    // Synchronizers
    reg s0 = 1'b1;
    reg s1 = 1'b1;
    always @(posedge clk) begin
        if(sample_enable) begin
            s0 <= rx;
            s1 <= s0;
        end
    end
    wire rx_clean = s1 && s0;
    //*************************************************************************
    // Rx State Machine
    reg [2:0] rx_state = 3'b0;
    reg [7:0] rx_data = 8'b0;
    reg [3:0] rx_count = 3'b0;
    reg [3:0] rx_delay = 4'b0;

    always @(posedge clk) begin
        if(sample_enable) begin
            case(rx_state)
            3'b000: begin                       // Look for start bit
                if(rx_clean == 1'b0) begin
                    rx_state <= 3'b001;
                end
            end
            3'b001: begin                       // Sample first data bit
                if(rx_delay == 4'b0111) begin
                    rx_data <= {rx_data[6:0],rx_clean};
                    rx_delay <= 4'b0;
                    rx_state <= 3'b010;
                end
                else begin
                    rx_delay <= rx_delay + 1;
                end
            end
            3'b010: begin                       // Sample the other data bits
                if(rx_delay == 4'b1111) begin
                    rx_data <= {rx_clean,rx_data[7:1]};
                    rx_delay <= 4'b0;
                    rx_count <= rx_count + 1;
                    if(rx_count == 3'b111) begin
                        rx_count <= 3'b0;
                        rx_state <= 3'b011;
                    end
                end
                else begin
                    rx_delay <= rx_delay + 1;
                end
            end
            3'b011: begin                       // Sample stop bit
                if(rx_delay == 4'b1111) begin
                    if(rx_clean == 1) begin
                        rx_delay <= 0;
                        if(rx_data == 8'd48) begin
                            led <= 0;
                        end
                        else if(rx_data == 8'd49) begin
                            led <= 1;
                        end
                        rx_state <= 3'b000;
                    end
                    else begin
                        rx_delay <= 0;
                        rx_state <= 3'b100;
                    end
                end
                else begin
                    rx_delay <= rx_delay + 1;
                end
            end
            3'b100: begin                       // Frame error, wait till rx_clean is high,
                if(rx_clean) begin              // then go to rx_state 0
                    rx_state <= 3'b000;
                end
            end
            default begin
                rx_state <= 3'b000;
            end
            endcase
        end
    end
    //*************************************************************************
    // Tx State Machine
    reg [2:0] tx_state = 3'b0;
    reg [7:0] tx_data = 8'b0;
    reg [3:0] tx_count = 4'b0;
    reg [3:0] tx_delay = 4'b0;
    reg tx_start = 1'b1;

    always @(posedge clk) begin
        if(sample_enable) begin
            case(tx_state)
            3'b000: begin                       // Wait for start signal and begin start bit
                if(tx_start) begin
                    tx_start <= 0;
                    tx_state <= 3'b001;
                    tx_count <= 4'b1;
                    tx <= 0;                    // Start bit
                end
            end
            3'b001: begin
                if(tx_delay == 4'b1111) begin   // Finish start bit, send data bits, begin stop bit
                    tx_delay <= 0;
                    tx_count <= tx_count + 1;
                    if(tx_count == 4'b1001) begin
                        tx <= 1;                // Stop bit
                        tx_state <= 3'b010;
                    end
                    else begin
                        tx <= tx_data[0];       // Data bit
                        tx_data <= {0,tx_data[7:1]};
                    end
      
                end
                else begin
                    tx_delay <= tx_delay + 1;
                end
            end
            3'b010: begin                       // Finish stop bit
                if(tx_delay == 4'b1111) begin
                    tx_delay <= 0;
                    tx_count <= 0;
                    tx_state <= 3'b000;
                end
                else begin
                    tx_delay <= tx_delay + 1;
                end
            end
            endcase
        end
    end
    //*************************************************************************
endmodule