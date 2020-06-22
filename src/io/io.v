module io(input wire clk,
          input wire [7:0] din,
          input wire [7:0] address,
          input wire w_en,
          input wire r_en,
          output wire [7:0] dout,
          output wire [7:0] io_pins,
);
    //***************************************************************
    // Manually Instantiate Pin Primitives Ror Tri-state Control
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) io_block_instance0 [7:0](
        .PACKAGE_PIN(io_pins),
        .OUTPUT_ENABLE(dir),
        .D_OUT_0(port),
        .D_IN_0(pins)
    );
    //***************************************************************
    // GPIO
    
    reg [7:0] dir;
    reg [7:0] port;
    wire [7:0] pins;

    always @(posedge clk) begin
        if(address == 8'h00) begin             // DIR
            if(w_en)
                dir <= din;
            if(r_en)
                dout <= dir;
        end
        else if(address == 8'h01) begin        // PORT
            if(w_en)
                port <= din;
            if(r_en)
                dout <= port;
        end
        else if(address == 8'h02) begin        // PINS
            if(r_en)
                dout <= pins;
        end
    end
    //***************************************************************
    // Counter/Timer
    /*
    reg [7:0] counter;
    reg [15:0] prescaler;
    reg [15:0] scaleFactor
    reg [7:0] cmpr0;
    reg [7:0] cmpr1;
    reg [1:0] counterMode;
    wire match0;
    wire match1;
    wire scaled;
    reg out0;
    reg out1;

    // prescaler
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

    // counter
    always @(posedge clk) begin
        if(scaled) begin
            counter <= counter + 1;
            if(counterMode == 2'b00) begin                  //CTC mode
                if(match0) begin
                    counter <= 0;
                end
            end
        end
    end

    // comparators
    assign match0 = (counter == cmpr0) ? 1 : 0;
    assign match1 = (counter == cmpr1) ? 1 : 0;*/
    //***************************************************************
endmodule