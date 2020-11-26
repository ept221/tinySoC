module control(input wire clk,
               input wire reset,
               input wire [15:0] iMemOut,
               input wire carryFlag,
               input wire zeroFlag,
               input wire negativeFlag,
               input wire interruptEnable,
               output reg [1:0] regFileSrc,
               output reg [3:0] regFileOutBSelect,
               output reg regFileWriteEnable,  
               output reg regFileIncPair,        
               output reg regFileDecPair,            
               output reg aluSrcASelect,
               output reg [1:0] aluSrcBSelect,
               output reg [3:0] aluMode,
               output reg [2:0] dMemDataSelect,
               output reg [1:0] dMemIOAddressSelect,
               output reg dMemIOWriteEn,
               output reg dMemIOReadEn,
               output reg [1:0] statusRegSrcSelect,
               output reg flagEnable,
               output reg [2:0] iMemAddrSelect,
               output reg iMemReadEnable,
               output reg pcWriteEn,
               output reg [15:0] interruptVector,
               input wire interrupt_0,
               input wire interrupt_1,
               input wire interrupt_2,
               input wire interrupt_3,
               output reg interrupt_0_clr,
               output reg interrupt_1_clr,
               output reg interrupt_2_clr,
               output reg interrupt_3_clr,
               output wire reset_out
);    
    //****************************************************************************************************
    // States
    localparam PART1 = 4'b0000;           // Part 1 of instruction (may be single or multi-cycle)
    localparam PART2 = 4'b0010;           // Part 2 of generic multi-cycle instruction
    localparam PART3 = 4'b0100;           // Part 3 of generic multi-cycle instruction

    localparam JMP = 4'b0001;             // Fetch address, and perform a jump
    localparam CALL = 4'b0011;            // Fetch address, and perform a call
    localparam INTERRUPT = 4'b0101;       // Push MSBs of return address, and jump to the ISR
    localparam START = 4'b0111;           // Initial state, wait 40 cycles, and fetch first instruction
    localparam RESET = 4'b1001;           // Reset State

    reg [3:0] state = START;
    reg [3:0] nextState;
    always @(posedge clk) begin
        state <= nextState;
    end
    //****************************************************************************************************
    // Reset Control
    reg reset_d0 = 1;
    reg reset_d1 = 1;
    always @(posedge clk) begin
        reset_d0 <= reset;
        reset_d1 <= reset_d0;
    end

    assign reset_out = (state[3:1] == RESET[3:1]) ? 1'b1 : 1'b0;
    //****************************************************************************************************
    // Delayed start counter
    reg [5:0] delay = 0;
    always @(posedge clk) begin
        if(state == START) begin
            delay = delay + 1;
        end
        else begin
            delay <= 0;
        end
    end
    //****************************************************************************************************
    // Logic for jmp, call, and ret conditions
    reg condition;
    always @(*) begin
        case(iMemOut[15:13])
        3'b000:    condition = 1'b1;
        3'b001:    condition = (carryFlag);
        3'b010:    condition = (~carryFlag);
        3'b011:    condition = (zeroFlag);
        3'b100:    condition = (~zeroFlag);
        3'b101:    condition = (negativeFlag);
        3'b110:    condition = (~negativeFlag);
        3'b111:    condition = 1'b1;
        endcase 
    end
    //****************************************************************************************************
    // Interrupt vectoring
    always @(*) begin
        if(interrupt_0) begin
            interruptVector = 16'd20;
        end
        else if(interrupt_1) begin
            interruptVector = 16'd30;
        end
        else if(interrupt_2) begin
            interruptVector = 16'd40;
        end
        else if(interrupt_3) begin
            interruptVector = 16'd50;
        end
        else begin
            interruptVector = 16'd0;
        end
    end

    always @(*) begin
        if(state == INTERRUPT && interrupt_0) begin
            interrupt_0_clr = 1;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_1) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 1;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_2) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 1;
            interrupt_3_clr = 0;
        end
        else if(state == INTERRUPT && interrupt_3) begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 1;
        end
        else begin
            interrupt_0_clr = 0;
            interrupt_1_clr = 0;
            interrupt_2_clr = 0;
            interrupt_3_clr = 0;
        end
    end

    wire interrupt = interrupt_0 || interrupt_1 || interrupt_2 || interrupt_3;

    // The HLT instruction cannot be interrupted, and neither can the clear status register
    // instruction (CSR), if it is clearing the global interrupt enable flag.
    wire uninterruptible = (iMemOut == 16'h00f0) || (iMemOut[7:0] == 8'he8 && iMemOut[11] == 1'b0);

    //****************************************************************************************************
    // Main Decoder
    always @(*) begin
        if(reset_d1 == 1'b0 && state != START && state != RESET) begin
            regFileSrc = 2'b00;                 // aluOut
            regFileOutBSelect = 4'b1110;        // lower SP reg
            regFileWriteEnable = 1'b0;
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b0;               // From the register file
            aluSrcBSelect = 2'b00;              // regFileOutB
            aluMode = 4'b0000;                  // Pass B
            dMemDataSelect = 3'b100;            // From LSBs of the current address
            dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
            dMemIOWriteEn = 1'd0;               // Need to push to the stack
            dMemIOReadEn = 1'b0;
            statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
            flagEnable = 1'b0;                  // Disable interrupts
            iMemAddrSelect = 3'b010;            // interruptVector
            iMemReadEnable = 1'b0;              // Wait till second stage to make the jump
            pcWriteEn = 1'd0;
            nextState = RESET;
        end
        else if(state[0] == 1'b0) begin
            if(interruptEnable && state == PART1 && interrupt && ~uninterruptible) begin
                regFileSrc = 2'b00;                 // aluOut
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b1;              // Need to push to the stack
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass B
                dMemDataSelect = 3'b100;            // From LSBs of the current address
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                dMemIOWriteEn = 1'd1;               // Need to push to the stack
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                flagEnable = 1'b1;                  // Disable interrupts
                iMemAddrSelect = 3'b010;            // interruptVector
                iMemReadEnable = 1'b0;              // Wait till second stage to make the jump
                pcWriteEn = 1'd0;
                nextState = INTERRUPT;
            end
            // [Type R-I]
            else if(iMemOut[0] == 1'b1 && (iMemOut[3:1] < 3'b111)) begin
                regFileSrc = 2'b00;                 // aluOut
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                regFileWriteEnable = 1'b1;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b10;              // From immediate 8-bit data
                aluMode = {1'b0,iMemOut[3:1]};
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b00;        // {12'b0,iMemOut[15:12]}
                dMemIOWriteEn = 1'd0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = (iMemOut[3:1] != 3'b000);  // Don't set flags on LDI
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'd1;
                nextState = PART1;
            end
            // [Type R-L] : IN
            else if(iMemOut[2:0] == 3'b010) begin
                regFileSrc = 2'b10;                 // dMemIOOut
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // From the register file. Doesn't really matter
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass B
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b01;        // {8'd0,iMemOut[11:4]};
                dMemIOWriteEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                if(state[2:1] == 2'b00) begin
                    dMemIOReadEn = 1'b1;
                    regFileWriteEnable = 1'b0;
                    iMemReadEnable = 1'b0;
                    pcWriteEn = 1'b0;
                    nextState = PART2;
                end
                else begin
                    dMemIOReadEn = 1'b0;
                    regFileWriteEnable = 1'b1;
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            end
            // [Type R-L] : OUT
            else if(iMemOut[2:0] == 3'b100) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass B
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b01;        // {8'd0,iMemOut[11:4]};
                dMemIOWriteEn = 1'b1;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut, pcPlusOne
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            // [Type R-R] and [Type R]
            else if(iMemOut[7:3] > 5'b00000 && iMemOut[7:3] < 5'b01110 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut
                regFileOutBSelect = iMemOut[11:8];  // SSSS, or in the case of Type R, just 0000
                regFileWriteEnable = 1'b1;
                regFileIncPair = 1'b0;            
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = iMemOut[6:3];
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, but doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = (iMemOut[7:3] != 5'b01001);   // MOV doesn't affect flags
                iMemReadEnable = 1'b1;
                iMemAddrSelect = 3'b000;            // pcOut
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            // [Type R-RP]
            else if(iMemOut[7:3] >= 5'b01110 && iMemOut[7:3] < 5'b10100 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b10;                         // dMemIOOut
                regFileOutBSelect = iMemOut[11:8];          // PPPP
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b1110;                  // Pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut

                if(iMemOut[7:3] == 5'b01110 || iMemOut[7:3] == 5'b01111 || iMemOut[7:3] == 5'b10000) begin // if store
                    regFileWriteEnable = 1'b0;
                    dMemIOWriteEn = 1'b1;
                    dMemIOReadEn = 1'b0;

                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
                else begin      // if load
                    regFileWriteEnable = 1'b1;
                    dMemIOWriteEn = 1'b0;

                    if(state == PART1) begin
                        dMemIOReadEn = 1'b1;
                        iMemReadEnable = 1'b0;
                        pcWriteEn = 1'b0;
                        nextState = PART2;
                    end
                    else begin
                        dMemIOReadEn = 1'b0;
                        iMemReadEnable = 1'b1;
                        pcWriteEn = 1'b1;
                        nextState = PART1;
                    end
                end

                if(state == PART1) begin
                    if(iMemOut[7:3] == 5'b01110 || iMemOut[7:3] == 5'b10001) begin
                        regFileIncPair = 1'b0;
                        regFileDecPair = 1'b0;
                    end
                    else if(iMemOut[7:3] == 5'b01111 || iMemOut[7:3] == 5'b10010) begin
                        regFileIncPair = 1'b1;
                        regFileDecPair = 1'b0;
                    end
                    else begin
                        regFileIncPair = 1'b0;
                        regFileDecPair = 1'b1;
                    end
                end
                else begin
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                end
            end
            // [Type RP]
            else if((iMemOut[7:3] == 5'b10100 || iMemOut[7:3] == 5'b10101 || iMemOut[7:3] == 5'b10110) && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                         // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[11:8];          // PPPP
                regFileWriteEnable = 1'b0;
                aluSrcASelect = 1'b0;                       // regFileOutA, doesn't really matter
                aluSrcBSelect = 2'b00;                      // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                          // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;                    // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;                // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;                 // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                if(iMemOut[7:3] == 5'b10100) begin              // IRP
                    regFileIncPair = 1'b1;
                    regFileDecPair = 1'b0;
                    iMemAddrSelect = 3'b000;                    // pcOut
                end
                else if(iMemOut[7:3] == 5'b10101) begin         // DRP
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b1;
                    iMemAddrSelect = 3'b000;                    // pcOut
                end
                else begin                                      // JMPI condition
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                    if(condition) begin
                        iMemAddrSelect = 3'b100;                // {regFileOutC, regFileOutB}
                    end
                    else begin
                        iMemAddrSelect = 3'b000;                // pcOut
                    end
                end
                nextState = PART1;
            end
            // JMP
            else if(iMemOut[7:3] == 5'b10111 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                             // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[15:12];             // same as inSelect
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;                           // regFileOutA, doesn't really matter
                aluSrcBSelect = 2'b00;                          // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                              // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;                        // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;                    // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;                     // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                if(condition) begin
                    iMemAddrSelect = 3'b000;                    // pcOut
                    nextState = JMP;
                end
                else begin
                    iMemAddrSelect = 3'b001;                    // pcPlusOne
                    nextState = PART1;
                end
            end
            // CALL
            else if(iMemOut[7:3] == 5'b11000 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                aluSrcASelect = 1'b0;               // From the register file, doesn't really matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass B, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                dMemDataSelect = 3'b010;            // From LSBs of the PC + 1
                iMemReadEnable = 1'b1;
                if(condition) begin                 // If the call condition is met
                    regFileDecPair = 1'b1;          // Deincrement the SP
                    dMemIOWriteEn = 1'b1;           // Write the LSBs of the PC to the stack
                    iMemAddrSelect = 3'b000;        // pcOut, read the address we need to jump to
                    pcWriteEn = 1'b0;               // Dont write to the PC because we still need to get the MSBs
                    nextState = CALL;
                end
                else begin                          // If the call condition is not met
                    regFileDecPair = 1'b0;
                    dMemIOWriteEn = 1'b0;
                    iMemAddrSelect = 3'b001;        // pcPlusOne
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            end
            // RET
            else if(iMemOut[7:3] == 5'b11001 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // From the register file
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b10;        // {regFileOutC,regFileOutB} + 1, SP + 1
                dMemIOWriteEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                if(state == PART1) begin
                    if(condition) begin
                        dMemIOReadEn = 1'b1;        // Pop the MSBs of the return address
                        regFileIncPair = 1'b1;      // Increment the SP
                        iMemReadEnable = 1'b0;
                        pcWriteEn = 1'b0;
                        nextState = PART2;
                    end
                    else begin
                        dMemIOReadEn = 1'b0;
                        regFileIncPair = 1'b0;
                        iMemReadEnable = 1'b1;
                        pcWriteEn = 1'b1;
                        nextState = PART1;
                    end
                    iMemAddrSelect = 3'b000;        // pcOut (Only matters if condition is not met)
                end
                else if(state == PART2) begin
                    dMemIOReadEn = 1'b1;            // Pop the LSBs of the return address
                    regFileIncPair = 1'b1;          // Increment the SP
                    iMemAddrSelect = 3'b101;        // returnReg,dMemIOOut
                    iMemReadEnable = 1'b0;
                    pcWriteEn = 1'b0;
                    nextState = PART3;
                end
                else begin
                    dMemIOReadEn = 1'b0;
                    regFileIncPair = 1'b0;
                    iMemAddrSelect = 3'b101;        // returnReg,dMemIOOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            end
            // PUS
            else if(iMemOut[7:3] == 5'b11010 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b1;
                aluSrcASelect = 1'b1;               // From zero-extended status register
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b1110;                  // pass A
                dMemDataSelect = 3'b000;            // aluOut
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}
                dMemIOWriteEn = 1'b1;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end
            // POS
            else if(iMemOut[7:3] == 5'b11011 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = 4'b1110;        // lower SP reg
                regFileWriteEnable = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // From register file, doesn't really matter
                aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                aluMode = 4'b0000;                  // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}
                dMemIOWriteEn = 1'b0;
                statusRegSrcSelect = 2'b10;         // dMemIOOut[3:0]
                flagEnable = 1'b1;
                iMemAddrSelect = 3'b000;            // pcOut
                if(state == PART1) begin
                    dMemIOReadEn = 1'b1;
                    regFileIncPair = 1'b1;
                    iMemReadEnable = 1'b0;
                    pcWriteEn = 1'b0;
                    nextState = PART2;
                end
                else begin
                    dMemIOReadEn = 1'b0;
                    regFileIncPair = 1'b0;
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            end
            // SSR and CSR
            else if((iMemOut[7:3] == 5'b11100 || iMemOut[7:3] == 5'b11101) && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b1;               // From zero-extended status register
                aluSrcBSelect = 2'b01;              // {4'd0,iMemOut[11:8]}, immediate 4-bit mask
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b01;         // ALU output
                flagEnable = 1'b1;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
                if(iMemOut[7:3] == 5'b11100) begin  // SSR
                    aluMode = 4'b0010;              // OR mask
                end
                else begin                          // CSR
                    aluMode = 4'b0001;              // AND mask
                end
            end
            // HLT
            else if(iMemOut[7:3] == 5'b11110 && iMemOut[2:0] == 3'b000) begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b0;
                pcWriteEn = 1'b0;
                nextState = PART1;
            end
            // NOP   
            else begin
                regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                regFileWriteEnable = 1'b0;
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                aluSrcASelect = 1'b0;               // regFileOutA
                aluSrcBSelect = 2'b00;              // regFileOutB
                aluMode = 4'b0000;                  // Pass B, doesn't really matter
                dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                dMemIOWriteEn = 1'b0;
                dMemIOReadEn = 1'b0;
                statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                flagEnable = 1'b0;
                iMemAddrSelect = 3'b000;            // pcOut
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = PART1;
            end     
        end
        else begin
            case(state[3:1])
                RESET[3:1]: begin
                    regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                    regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1;
                    nextState = (reset_d1 == 1'd1) ? PART1 : RESET;
                end
                START[3:1]: begin
                    regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                    regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = (delay == 6'd40) ? 1 : 0;
                    nextState = (delay == 6'd40) ? PART1 : START;
                end
                INTERRUPT[3:1]: begin
                    regFileSrc = 2'b00;                 // aluOut
                    regFileOutBSelect = 4'b1110;        // lower SP reg
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b1;              // Need to push to the stack
                    aluSrcASelect = 1'b0;               // From the register file
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass B
                    dMemDataSelect = 3'b011;            // From MSBs of the current address
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                    dMemIOWriteEn = 1'd1;               // Need to push to the stack
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b11;         // Disable interrupts and save all other flags
                    flagEnable = 1'b1;                  // Need to disable interrupts
                    iMemAddrSelect = 3'b010;            // interruptVector
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'd1;
                    nextState = PART1;
                end
                JMP[3:1]: begin
                    regFileSrc = 2'b00;                             // aluOut, doesn't really matter
                    regFileOutBSelect = iMemOut[15:12];             // same as inSelect
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                    aluSrcASelect = 1'b1;                           // From zero-extended status register
                    aluSrcBSelect = 2'b00;                          // regFileOutB, doesn't really matter
                    aluMode = 4'b0000;                              // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;                        // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;                    // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;                     // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    iMemAddrSelect = 3'b011;                        // iMemOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
                CALL[3:1]: begin
                    regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                    regFileOutBSelect = 4'b1110;        // lower SP reg
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    aluSrcASelect = 1'b0;               // From the register file, doesn't really matter
                    aluSrcBSelect = 2'b00;              // regFileOutB, doesn't really matter
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, SP
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;     // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    dMemDataSelect = 3'b001;        // From MSBs of the PC + 1
                    iMemReadEnable = 1'b1;          // read the instruction at the address we call to
                    regFileDecPair = 1'b1;          // Deincrement the SP
                    dMemIOWriteEn = 1'b1;           // Write the MSBs of the PC to the stack
                    iMemAddrSelect = 3'b011;        // iMemOut, the address of the place we call to
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
                default begin
                    regFileSrc = 2'b00;                 // aluOut, doesn't really matter
                    regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesn't really matter
                    regFileWriteEnable = 1'b0;
                    regFileIncPair = 1'b0;
                    regFileDecPair = 1'b0;
                    aluSrcASelect = 1'b0;               // regFileOutA
                    aluSrcBSelect = 2'b00;              // regFileOutB
                    aluMode = 4'b0000;                  // Pass B, doesn't really matter
                    dMemDataSelect = 3'b000;            // aluOut, doesn't really matter
                    dMemIOAddressSelect = 2'b00;        // {regFileOutC,regFileOutB}, doesn't really matter
                    dMemIOWriteEn = 1'b0;
                    dMemIOReadEn = 1'b0;
                    statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
                    flagEnable = 1'b0;
                    iMemAddrSelect = 3'b000;            // pcOut
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = PART1;
                end
            endcase
        end
    end
endmodule