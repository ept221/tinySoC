    reg [7:0] IOOut = 0;
    reg [7:0] dir = 0;
    reg [7:0] port = 0;
    wire [7:0] pins;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) io_block_instance0 [7:0](
        .PACKAGE_PIN(io),
        .OUTPUT_ENABLE(dir),
        .D_OUT_0(port),
        .D_IN_0(pins)
    );

    // This is the logic for the I/O ports
    always @(posedge clk) begin
        if(dMemIOAddress == 16'h1000) begin
            if(IOWriteEn)
                dir <= dMemIOIn;
            if(IOReadEn)
                IOOut <= dir;
        end
        else if(dMemIOAddress == 16'h1001) begin
            if(IOWriteEn)
                port <= dMemIOIn;
            if(IOReadEn)
                IOOut <= port;
        end
        else if(dMemIOAddress == 16'h1002) begin
            if(IOReadEn)
                IOOut <= pins;
        end
    end


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