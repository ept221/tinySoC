module top(input wire clk, output wire PIN_6, output wire PIN_7, output wire PIN_8, output wire PIN_9,
                           output wire PIN_10, output wire PIN_11, output wire PIN_12, output wire PIN_13);
    //***************************************************************
    // Instantiate Control Logic
    //***************************************************************
    // Register File Source Mux
    wire [1:0] regFileSrc;                      //*
    always @(*) begin
        case(regFileSrc)
        2'b00:  regFileIn = aluOut;             // From the ALU output
        2'b01:  regFileIn = iMemOut[11:4];      // From the instruction memory output
        2'b10:  regFileIn = dMemIOOut;          // From the data memory output
        2'b11:  regFileIn = aluOut;             // From the ALU output, for default
        endcase
    end
    //***************************************************************
    // Register File
    wire [3:0] regFileOutBSelect;               //*
    reg [7:0] regFileIn;   
    wire regFileWriteEnable;                    //*
    wire regFileIncPair;                        //*
    wire regFileDecPair;                        //*
    wire [7:0] regFileOutA;
    wire [7:0] regFileOutB;
    wire [7:0] regFileOutC;
    //***************************************************************
    // ALU Mux A
    wire aluSrcASelect;                         //*
    always @(*) begin
        case(aluSrcASelect)
        1'b0:   dataA = {4'd0,statusOut};       // From zero-extended status register
        1'b1:   dataA = regFileOutA;            // From the register file
        endcase
    end
    //***************************************************************
    // ALU Mux B
    wire [1:0] aluSrcBSelect;                   //*
    always @(*) begin
        case(aluSrcBSelect)
        2'b00:  dataB = regFileOutB;            // From the register file
        2'b01:  dataB = {4'd0,iMemOut[11:8]};   // From immediate 4-bit mask
        2'b10:  dataB = iMemOut[11:4];          // From immediate 8-bit data
        2'b11:  dataB = 8'd0;                   // Default to zero
        endcase
    end
    //***************************************************************
    // ALU
    wire [3:0] aluMode;                         //*
    wire carryOut;
    wire zeroOut;
    wire negitiveOut;
    wire [7:0] aluOut;
    reg [7:0] dataA;
    reg [7:0] dataB;
    //***************************************************************
    // Data Memory and I/O Data Mux
    wire [1:0] dMemDataSelect;                  //*
    always @(*) begin
        case(dMemDataSelect)
            2'b00:  dMemIOIn = pcPlusOne[15:8];   // From MSBs of the PC + 1
            2'b01:  dMemIOIn = pcPlusOne[7:0];    // From LSBs of the PC + 1
            2'b10:  dMemIOIn = aluOut;            // From the ALU
            2'b11:  dMemIOIn = 8'd0;              // Default to zero
        endcase
    end
    //***************************************************************
    // Data Memory and I/O Address Mux
    wire [1:0] dMemIOAddressSelect;                     //*
    always @(*) begin
        case(dMemIOAddressSelect)
            2'b00:   dMemIOAddress = {regFileOutC,regFileOutB};
            2'b01:   dMemIOAddress = {8'b00010000,iMemOut[11:4]};
            2'b10:   dMemIOAddress = {regFileOutC,regFileOutB} + 16'b1;
            default  dMemIOAddress = {regFileOutC,regFileOutB};
        endcase
    end
    //***************************************************************
    // Data Memory and IO
    reg [7:0] dMemIOIn;
    reg [7:0] dMemIOOut;
    wire [7:0] dMemOut;
    reg [7:0] IOOut = 0;
    reg [15:0] dMemIOAddress;
    wire dMemIOWriteEn;                           //*
    wire dMemIOReadEn;                            //*

    reg dMemWriteEn;
    reg dMemReadEn;
    reg IOWriteEn;
    reg IOReadEn;

    // This is the logic for the address map for the data memory
    // and I/O. The data memory will be from 0x0000 through 0x0FFF
    // and the I/O will be from 0x1000 through 0x10FF.
    reg foo = 0;
    always @(*) begin
        if(dMemIOAddress > 16'h0FFF) begin
            dMemWriteEn = 0;
            dMemReadEn = 0;
            IOWriteEn = dMemIOWriteEn;
            IOReadEn = dMemIOReadEn;
            dMemIOOut = IOOut;
            foo = 1;
        end
        else begin
            foo = 0;
            dMemWriteEn = dMemIOWriteEn;
            dMemReadEn = dMemIOReadEn;
            IOWriteEn = 0;
            IOReadEn = 0;
            dMemIOOut = dMemOut;
        end
    end
    reg [7:0] dir = 0;
    reg [7:0] port = 0;
    wire [7:0] pins;
    wire [7:0] IO_PINS = {PIN_13,PIN_12,PIN_11,PIN_10,PIN_9,PIN_8,PIN_7,PIN_6};
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) io_block_instance0 [7:0](
        .PACKAGE_PIN(IO_PINS),
        .OUTPUT_ENABLE(dir),
        .D_OUT_0(port),
        .D_IN_0(pins)
    );

    //This is the logic for the I/O ports
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
    //***************************************************************
    // Status Register Source Mux
    wire [1:0] statusRegSrcSelect;              //*
    always @(*) begin
        case(statusRegSrcSelect)
        2'b00:  statusIn = {interruptEnable,negitiveOut,zeroOut,carryOut};      // ALU flags out and save interrupt enable status
        2'b01:  statusIn = aluOut[3:0];                                         // ALU output
        2'b10:  statusIn = dMemIOOut[3:0];                                      // Data memory output
        2'b11:  statusIn = 4'd0;                                                // Default to zero
        endcase
    end
    //***************************************************************
    // Status Register
    reg carryFlag = 0;
    reg zeroFlag = 0;
    reg negativeFlag = 0;
    reg interruptEnable = 0;
    wire flagEnable;                            //*
    reg [3:0] statusIn;
    wire [3:0] statusOut = {interruptEnable,negativeFlag,zeroFlag,carryFlag};

    always @(posedge clk) begin
        if(flagEnable) begin
            carryFlag <= statusIn[0];
            zeroFlag <= statusIn[1];
            negativeFlag <= statusIn[2];
            interruptEnable <= statusIn[3];
        end
    end
    //***************************************************************
    // Return Register
    reg [7:0] returnReg = 0;
    always @(posedge clk) begin
        returnReg <= dMemIOOut;
    end 
    //***************************************************************
    // Instruction Memory Address Mux
    wire [15:0] interruptVector = 16'h00FF;
    wire [2:0] iMemAddrSelect;                  //*
    always @(*) begin
        case(iMemAddrSelect)
        3'b000:     iMemAddress = pcPlusOne;
        3'b001:     iMemAddress = pcOut;
        3'b010:     iMemAddress = interruptVector;
        3'b011:     iMemAddress = iMemOut;
        3'b100:     iMemAddress = {regFileOutC, regFileOutB};
        3'b101:     iMemAddress = {returnReg,dMemIOOut};
        default     iMemAddress = 16'd0;      
        endcase
    end
    //***************************************************************
    // Instruction Memory
    reg [15:0] iMemAddress;
    wire [15:0] iMemOut;
    wire iMemReadEnable;                        //*
    //***************************************************************
    // PC and pcPlusOne adder
    reg [15:0] pc = 16'd1;
    wire [15:0] pcIn = iMemAddress + 1;
    wire [15:0] pcOut = pc;
    wire [15:0] pcPlusOne = pcOut + 1;
    wire pcWriteEn;                             //*
    always @(posedge clk) begin
        if(pcWriteEn)
            pc <= pcIn;
    end
    //***************************************************************
    control cntrl(.clk(clk),
                  .iMemOut(iMemOut),
                  .carryFlag(carryFlag),
                  .zeroFlag(zeroFlag),
                  .negativeFlag(negativeFlag),
                  .regFileSrc(regFileSrc),
                  .regFileOutBSelect(regFileOutBSelect),
                  .regFileWriteEnable(regFileWriteEnable),
                  .regFileIncPair(regFileIncPair),
                  .regFileDecPair(regFileDecPair),
                  .aluSrcASelect(aluSrcASelect),
                  .aluSrcBSelect(aluSrcBSelect),
                  .aluMode(aluMode),
                  .dMemDataSelect(dMemDataSelect),
                  .dMemIOAddressSelect(dMemIOAddressSelect),
                  .dMemIOWriteEn(dMemIOWriteEn),
                  .dMemIOReadEn(dMemIOReadEn),
                  .statusRegSrcSelect(statusRegSrcSelect),
                  .flagEnable(flagEnable),
                  .iMemAddrSelect(iMemAddrSelect),
                  .iMemReadEnable(iMemReadEnable),
                  .pcWriteEn(pcWriteEn)
    );
    regFile registerFile(.inSelect(iMemOut[15:12]),
                         .outBselect(regFileOutBSelect),
                         .in(regFileIn),
                         .write_en(regFileWriteEnable),
                         .inc(regFileIncPair),
                         .dec(regFileDecPair),
                         .clk(clk),
                         .outA(regFileOutA),
                         .outB(regFileOutB),
                         .outC(regFileOutC)
    );
    alu ALU(.dataA(dataA),
            .dataB(dataB),
            .mode(aluMode),
            .cin(carryFlag),
            .out(aluOut),
            .cout(carryOut),
            .zout(zeroOut),
            .nout(negitiveOut)
    );
    d_ram dataMemory(.din(dMemIOIn),
                     .w_addr(dMemIOAddress),
                     .w_en(dMemWriteEn),
                     .r_addr(dMemIOAddress),
                     .r_en(dMemReadEn),
                     .clk(clk),
                     .dout(dMemOut)
    );
    i_ram instructionMemory(.din(16'd0),
                            .w_addr(16'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );
endmodule