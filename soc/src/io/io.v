module io(input wire clk,
          input wire [7:0] din,
          input wire [7:0] address,
          input wire w_en,
          input wire r_en,
          output reg [7:0] dout,
          inout wire [7:0] io_pins,
          input wire rx,
          output reg tx,
          output reg top_flag = 0,
          output reg match0_flag = 0,
          output reg match1_flag = 0,
          input wire top_flag_clr,
          input wire match0_flag_clr,
          input wire match1_flag_clr
);
    //***************************************************************
    // GPIO 
    reg [7:0] dir = 0;
    reg [7:0] port = 0;
    wire [7:0] pins;

    //***************************************************************
    // Manually Instantiate Pin Primitives For Tri-state Control
    
    // Logic to select counter output or gpio for pins 6 and 7
    wire pin_6 = (counterControl[2] == 1) ? out0 : port[6];
    wire pin_7 = (counterControl[3] == 1) ? out1 : port[7];

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) io_block_instance0 [7:0](
        .PACKAGE_PIN(io_pins),
        .OUTPUT_ENABLE(dir),
        .D_OUT_0({pin_7,pin_6,port[5:0]}),
        .D_IN_0(pins)
    );

    //***************************************************************
    // 8-bit Counter/Timer

    // Prescaler registeres
    reg [15:0] scaleFactor = 0;
    reg [15:0] prescaler = 0;

    // Counter/Timer registers
    reg [7:0] counterControl = 0;
    reg [7:0] cmpr0 = 0;
    reg [7:0] cmpr1 = 0;
    reg [7:0] counter = 0;

    // Output registers
    reg out0 = 0;
    reg out1 = 0;

    // Internal signals 
    wire match0;
    wire match1;
    wire top;
    reg scaled = 0;

    // Prescaler
    always @(posedge clk) begin
        if(prescaler == scaleFactor) begin
            scaled <= 1;
            prescaler <= 0;
        end
        else begin
            scaled <= 0;
            prescaler <= prescaler + 1;
        end
    end

    // Counter/Timer
    always @(posedge clk) begin
        if(scaled) begin
            if(counterControl[1:0] == 2'b00) begin          // Idle mode
                counter <= 0;                               // Clear the counter
                out0 <= 0;
                out1 <= 0;
            end
            else if(counterControl[1:0] == 2'b01) begin     // CTC mode
                if(match0) begin                            // On match0:
                    counter <= 0;                           // Reset the counter
                    out0 <= ~out0;                          // Toggle the output
                end
                else begin
                    counter <= counter + 1;
                end
            end
            else if(counterControl[1:0] == 2'b10) begin     // PWM mode
                if(counter == 8'd255) begin                 // If finished 256 cycles
                    out0 <= 1;                              // On next edge (start of zero), set the outputs to 1
                    out1 <= 1;
                end
                else begin
                    if(match0) begin                        // On match0:
                        out0 <= 0;                          // clear out0
                    end
                    if(match1) begin                        // On match1:
                        out1 <= 0;                          // clear out1
                    end
                end
                counter <= counter + 1;
            end
        end
    end

    // Comparators
    assign top = (counter == 255) ? 1 : 0;
    assign match0 = (counter == cmpr0) ? 1 : 0;
    assign match1 = (counter == cmpr1) ? 1 : 0;
    //***************************************************************
    // Interrupts
    reg top_old;
    reg match0_old;
    reg match1_old;
    always @(posedge clk) begin
        // Needed to detect edges
        top_old <= top;
        match0_old <= match0;
        match1_old <= match1;

        // Top
        if(top_flag_clr)
            top_flag <= 0;
        else if(address == 8'h09 && w_en)                           // Interrupt flag register
            top_flag <= din[0];
        else if(top && (~top_old) && counterControl[4])
            top_flag <= 1;

        // Match0
        if(match0_flag_clr)
            match0_flag <= 0;
        else if(address == 8'h09 && w_en)                           // Interrupt flag register
            match0_flag <= din[1];
        else if(match0 && (~match0_old) && counterControl[5])
            match0_flag <= 1;

        // Match1
        if(match1_flag_clr)
            match1_flag <= 0;
        else if(address == 8'h09 && w_en)                           // Interrupt flag register
            match1_flag <= din[2];
        else if(match1 && (~match1_old) && counterControl[6])
            match1_flag <= 1;
    end

    //***************************************************************
    // Memory Map
    always @(posedge clk) begin
        case(address)
            8'h00: begin                            // DIR
                if(w_en)
                    dir <= din;
                if(r_en)
                    dout <= dir;
            end
            8'h01: begin                            // PORT
                if(w_en)
                    port <= din;
                if(r_en)
                    dout <= port;
            end
            8'h02: begin                            // PINS
                if(r_en)
                    dout <= pins;
            end
            8'h03: begin                            // scaleFactor LSB
                if(w_en)
                    scaleFactor[7:0] <= din;
                if(r_en)
                    dout <= scaleFactor[7:0];
            end
            8'h04: begin                            // scaleFactor MSB       
                if(w_en)
                    scaleFactor[15:8] <= din;
                if(r_en)
                    dout <= scaleFactor[15:8];
            end
            8'h05: begin                            // counterControl
                if(w_en)
                    counterControl <= din;
                if(r_en)
                    dout <= counterControl;
            end
            8'h06: begin                            // cmpr0
                if(w_en)
                    cmpr0 <= din;
                if(r_en)
                    dout <= cmpr0;
            end
            8'h07: begin                            // cmpr1
                if(w_en)
                    cmpr1 <= din;
                if(r_en)
                    dout <= cmpr1;
            end
            8'h08: begin                            // counter
                if(r_en)
                    dout <= counter;
            end
            8'h0A: begin
                if(w_en)
                    uart_control[7:2] <= din[7:2];
                if(r_en)
                    dout <= uart_control;
            end
            8'h0B: begin
                if(w_en)
                    tx_buffer <= din;
                if(r_en)
                    dout <= rx_buffer;
            end
        endcase
    end
    //***********************************************************************************
    // UART
    //***********************************************************************************
    // Might want an enable bit to switch from normal i/o operation to
    // uart mode.
    //***********************************************************************************
    //
    //                                uart_control
    // *--------*--------*--------*--------*--------*--------*--------*--------*
    // |        |        |        |        |        |        | tx_emty| rx_full|
    // *--------*--------*--------*--------*--------*--------*--------*--------*
    //     7        6        5        4        3        2        1        0   
    //***********************************************************************************
    reg [7:0] uart_control = 8'b00000011;
    reg [7:0] rx_buffer = 8'b0;
    reg [7:0] tx_buffer = 8'b0;
    //***********************************************************************************
    // Create sampling clock
    reg [7:0] uart_prescaler = 8'b0;
    reg sample_enable = 1'b0;
    always @(posedge clk) begin
        if(uart_prescaler == 8'd103) begin
            uart_prescaler <= 0;
            sample_enable <= 1;
        end
        else begin
            uart_prescaler <= uart_prescaler + 1;
            sample_enable <= 0;
        end
    end
    //***********************************************************************************
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
    //***********************************************************************************
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
                        rx_buffer <= rx_data;
                        uart_control[0] <= 1'b1;
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
        if(address == 8'h0B && r_en) begin
            uart_control[0] <= 0;
        end
        else if(sample_enable && rx_state == 3'b011 && rx_delay == 4'b1111 && rx_clean == 1) begin
            uart_control[0] <= 1;
        end
    end 
    //***********************************************************************************
    // Tx State Machine
    reg [2:0] tx_state = 3'b0;
    reg [7:0] tx_data = 8'b0;
    reg [3:0] tx_count = 4'b0;
    reg [3:0] tx_delay = 4'b0;

    always @(posedge clk) begin
        if(sample_enable) begin
            case(tx_state)
            3'b000: begin                       // Wait for start signal and begin start bit
                if(uart_control[1] == 1'b0) begin
                    tx_data <= tx_buffer;
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
        if(address == 8'h0B && w_en) begin
            uart_control[1] <= 0;
        end
        else if(sample_enable && tx_state == 3'b0 && uart_control[1] == 0) begin
            uart_control[1] <= 1;
        end
    end
    //***********************************************************************************
endmodule