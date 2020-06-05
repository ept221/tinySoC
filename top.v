module top(input wire clk);
	//***************************************************************
	// Instantiate Control Logic
	control cntrl(.clk(clk),
               	  .regFileSrc(regFileSrc),
               	  .regFileOutBSelect(regFileOutBSelect),
               	  .regFileWriteEnable(regFileWriteEnable),
               	  .regFileIncPair(regFileIncPair),
               	  .regFileDecPair(regFileDecPair),
               	  .aluSrcASelect(aluSrcASelect),
               	  .aluSrcBSelect(aluSrcBSelect),
               	  .aluMode(aluMode),
               	  .dMemDataSelect(dMemDataSelect),
               	  .dMemAddressSelect(dMemAddressSelect),
               	  .dMemWriteEn(dMemWriteEn),
               	  .dMemReadEn(dMemReadEn),
               	  .statusRegSrcSelect(statusRegSrcSelect),
               	  .flagEnable(flagEnable),
               	  .iMemAddrSelect(iMemAddrSelect),
               	  .iMemReadEnable(iMemReadEnable),
               	  .pcWriteEn(pcWriteEn)
	);
    //***************************************************************
    // Register File Source Mux
    wire [1:0] regFileSrc;  					//*
    always @(*) begin
        case(regFileSrc)
        2'b00:  regFileIn = aluOut;             // From the ALU output
        2'b01:  regFileIn = iMemOut[11:4];      // From the instruction memory output
        2'b10:  regFileIn = dMemOut;            // From the data memory output
        2'b11:  regFileIn = aluOut;             // From the ALU output, for default
        endcase
    end
    //***************************************************************
    // Register File
    wire [3:0] regFileOutBSelect;   //*
    wire [7:0] regFileIn;   
    wire regFileWriteEnable;        //*
    wire regFileIncPair;            //*
    wire regFileDecPair;            //*
    wire [7:0] regFileOutA;
    wire [7:0] regFileOutB;
    wire [7:0] regFileOutC;
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
    //***************************************************************
    // ALU Mux A
    wire aluSrcASelect;     					//*
    always @(*) begin
        case(aluSrcASelect)
        1'b0:   dataA = {4'd0,statusOut};       // From zero-extended status register
        1'b1:   dataA = regFileOutA;            // From the register file
        endcase
    end
    //***************************************************************
    // ALU Mux B
    wire [1:0] aluSrcBSelect; 					//*
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
    wire [3:0] aluMode; 						//*
    wire carryOut;
    wire zeroOut;
    wire negitiveOut;
    wire [7:0] aluOut;
    wire [7:0] dataA;
    wire [7:0] dataB;
    alu ALU(.dataA(dataA),
            .dataB(dataB),
            .mode(aluMode),
            .cin(carryFlag),
            .out(aluOut),
            .cout(carryOut),
            .zout(zeroOut),
            .nout(negitiveOut)
    );
    //***************************************************************
    // Data Memory and I/O Data Mux
    wire [1:0] dMemDataSelect; 					//*
    always @(*) begin
        case(dMemDataSelect)
            2'b00:  dMemIn = pcOut[15:8];       // From MSBs of the PC
            2'b01:  dMemIn = pcOut[7:0];        // From LSBs of the PC
            2'b10:  dMemIn = aluOut;            // From the ALU
            2'b11:  dMemIn = 8'd0;              // Default to zero
        endcase
    end
    //***************************************************************
    // Data Memory and I/O Address Mux
    wire dMemAddressSelect; 					//*
    always @(*) begin
        case(dMemAddressSelect)
            1'b0:   dMemAddress = {regFileOutC,regFileOutB};
            1'b1:   dMemAddress = {8'd0,iMemOut[11:4]};
        endcase
    end
    //***************************************************************
    // Data Memory
    wire [7:0] dMemIn;
    wire [7:0] dMemOut;
    wire [15:0] dMemAddress;
    wire dMemWriteEn;   						//*
    wire dMemReadEn;    						//*
    d_mem dataMemory(.din(dMemIn),
                     .w_addr(dMemAddress),
                     .w_en(dMemWriteEn),
                     .r_addr(dMemAddress),
                     .r_en(dMemReadEn),
                     .clk(clk),
                     .dout(dMemOut)
    );
    //***************************************************************
    // Status Register Source Mux
    wire [1:0] statusRegSrcSelect; 				//*
    always @(*) begin
        case(statusRegSrcSelect)
        2'b00:  statusIn = {interruptEnOut,negitiveOut,zeroOut,carryOut};       // ALU flags out and save interrupt enable status
        2'b01:  statusIn = aluOut[3:0];                                         // ALU output
        2'b10:  statusIn = dMemOut[3:0];                                        // Data memory output
        2'b11:  statusIn = 4'd0;                                                // Default to zero
        endcase
    end
    //***************************************************************
    // Status Register
    reg carryFlag;
    reg zeroFlag;
    reg negativeFlag;
    reg interruptEnable;
    wire flagEnable; 							//*
    wire [3:0] statusIn;
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
    reg [7:0] returnReg;
    always(@posedge clk) begin
        returnReg <= dMemOut;
    end 
    //***************************************************************
    // Instruction Memory Address Mux
    wire [2:0] iMemAddrSelect; 					//*
    always @(*) begin
        case(iMemAddrSelect)
        3'b000:     iMemAddress = pcPlusOne;
        3'b001:     iMemAddress = pcOut;
        3'b010:     iMemAddress = interruptVector;
        3'b011:     iMemAddress = iMemOut;
        3'b100:     iMemAddress = {regFileOutC, regFileOutB};
        3'b101:     iMemAddress = {returnReg,dMemOut};
        default     iMemAddress = 16'd0;      
        endcase
    end
    //***************************************************************
    // Instruction Memory
    wire [15:0] iMemAddress;
    wire [7:0] iMemOut;
    wire iMemReadEnable;						//*
    i_mem instructionMemory(.din(8'd0),
                            .w_addr(16'd0),
                            .w_en(1'd0),
                            .r_addr(iMemAddress),
                            .r_en(iMemReadEnable),
                            .clk(clk),
                            .dout(iMemOut)
    );
    //***************************************************************
    // PC and pcPlusOne adder
    reg [15:0] pc;
    wire [15:0] pcIn = iMemAddress + 1;
    wire [15:0] pcOut = pc;
    wire [15:0] pcPlusOne = pcOut + 1;
    wire pcWriteEn;								//*
    always @(posedge clk) begin
        if(pcWriteEn)
            pc <= pcIn;
    end
    //***************************************************************
endmodule