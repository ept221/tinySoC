module io(input wire clk,
          input wire [7:0] din,
          input wire [7:0] address,
          input wire w_en,
          input wire r_en,
          output reg [7:0] dout,
          inout wire [7:0] io_pins,
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
        endcase
    end
    //***************************************************************
endmodule