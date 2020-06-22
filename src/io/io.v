module io(input wire clk,
          input wire [7:0] din,
          input wire [7:0] address,
          input wire w_en,
          input wire r_en,
          output wire [7:0] dout,

          output reg [7:0] dir,
          output reg [7:0] port,
          input reg [7:0] pins
);
    //***************************************************************
    // GPIO
    
    always @(posedge clk) begin
        if(dMemIOAddress == 16'h1000) begin             // DIR
            if(w_en)
                dir <= din;
            if(r_en)
                dout <= dir;
        end
        else if(dMemIOAddress == 16'h1001) begin        // PORT
            if(w_en)
                port <= din;
            if(r_en)
                dout <= port;
        end
        else if(dMemIOAddress == 16'h1002) begin        // PINS
            if(r_en)
                dout <= pins;
        end
    end
    //***************************************************************
    // Counter/Timer

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
    assign match1 = (counter == cmpr1) ? 1 : 0;
    //***************************************************************
endmodule