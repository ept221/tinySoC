module io(input wire clk,
          input wire [7:0] din,
          input wire [7:0] address,
          input wire w_en,
          input wire r_en,
          output wire [7:0] dout,
          output wire [7:0] io_pins
);
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
    // GPIO 
    reg [7:0] dir;
    reg [7:0] port;
    wire [7:0] pins;
    //***************************************************************
    // 8-bit Counter/Timer

    // Prescaler registeres
    reg [15:0] scaleFactor;
    reg [15:0] prescaler;

    // Counter/Timer registers
    reg [7:0] counterControl;
    reg [7:0] cmpr0;
    reg [7:0] cmpr1;
    reg [7:0] counter;

    // Output registers
    reg out0;
    reg out1;

    // Interrupt registers
    reg top;
    reg cmpr0_interrupt;
    reg cmpr1_interrupt;

    // 
    wire match0;
    wire match1;
    wire scaled;

    // Prescaler
    always @(posedge clk) begin
        prescaler <= prescaler + 1;
        if(prescaler == scaleFactor) begin
            scaled <= 1;
            prescaler <= 0;
        end
        else begin
            scaled <= 0;
        end
    end

    // Counter/Timer
    always @(posedge clk) begin
        if(scaled) begin
            counter <= counter + 1;
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
            end
        end
    end

    // Interrupt flags
    always @(posedge clk) begin
        if(scaled) begin
            if(counter == 8'd255)
                top <= 1;
            else
                top <= 0;

            if(counter == cmpr0)
                cmpr0_interrupt <= 1;
            else 
                cmpr0_interrupt <= 0;

            if(counter == cmpr1)
                cmpr1_interrupt <= 1;
            else 
                cmpr1_interrupt <= 0;
        end
    end

    // Comparators
    assign match0 = (counter == cmpr0) ? 1 : 0;
    assign match1 = (counter == cmpr1) ? 1 : 0;
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
        endcase
    end
    //***************************************************************
endmodule