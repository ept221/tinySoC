wire [1:0] regFileSrc;
wire [3:0] regFileOutBSelect;
wire regFileWriteEnable;       
wire regFileIncPair;            
wire regFileDecPair;            
wire aluSrcASelect;
wire [1:0] aluSrcBSelect;
wire [3:0] aluMode;
wire [1:0] dMemDataSelect;
wire dMemAddressSelect;
wire dMemWriteEn;
wire dMemReadEn;
wire [1:0] statusRegSrcSelect;
wire flagEnable;
wire [2:0] iMemAddrAndPcInSelect;
wire iMemReadEnable;
wire pcWriteEn;

reg [2:0] state;
reg [2:0] nextState;
always @(posedge clk) begin
    state <= nextState;
end

always @(*) begin
    wire jmp;
    case(iMemOut[15:13])
    3'b000:    jmp = 1'b1;
    3'b001:    jmp = (carryFlag);
    3'b010:    jmp = (~carryFlag);
    3'b011:    jmp = (zeroFlag);
    3'b100:    jmp = (~zeroFlag);
    3'b101:    jmp = (negativeFlag);
    3'b111:    jmp = (~negativeFlag);
    endcase 
end

always @(*) begin
    if(state[0] == 1'b0) begin
        // [Type R-I]
        if(iMemOut[0] == 1'b1 && (iMemOut[3:1] < 3'b111)) begin
            regFileSrc = 2'b00;                 // aluOut
            regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesnt really matter
            regFileWriteEnable = 1'b1;
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;               // From the register file
            aluSrcBSelect = 2'b10;              // From immediate 8-bit data
            aluMode = {0,iMemOut[3:1]};
            dMemDataSelect = 2'b10;             // aluOut
            dMemAddressSelect = 1'b0;           // {12'b0,iMemOut[15:12]};
            dMemWriteEn = 1'd0;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b1;
            iMemAddrAndPcInSelect = 3'b001;
            iMemReadEnable = 1'b1;
            pcWriteEn = 1'd1;
            nextState = 3'b000;
        end
        // [Type R-L] : IN
        else if(iMemOut[2:0] == 3'b010) begin
            regFileSrc = 2'b00;                 // aluOut
            regFileOutBSelect = iMemOut[15:12]; // same as inSelect. Doesnt really matter
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;               // From the register file. Doesnt really matter
            aluSrcBSelect = 2'b00;              // regFileOutB
            aluMode = 4'b0000;                  // Pass B
            dMemDataSelect = 2'b10;             // aluOut, doesnt really matter
            dMemAddressSelect = 1'b1;           // {8'd0,iMemOut[11:4]};
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b1;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b0;
            iMemAddrAndPcInSelect = 3'b001;     // pcOut, pcPlusOne
            if(state[2:1] == 2'b00) begin
                regFileWriteEnable = 1'b0;
                iMemReadEnable = 1'b0;
                pcWriteEn = 1'b0;
                nextState = 3'b010;
            end
            else begin
                regFileWriteEnable = 1'b1;
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = 3'b000;
            end
        end
        // [Type R-L] : OUT
        else if(iMemOut[2:0] == 3'b100) begin
            regFileSrc = 2'b00;                 // aluOut, doesnt really matter
            regFileOutBSelect = iMemOut[15:12]; // same as inSelect
            regFileWriteEnable = 1'b0;
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;               // From the register file
            aluSrcBSelect = 2'b00;              // regFileOutB
            aluMode = 4'b0000;                  // Pass B
            dMemDataSelect = 2'b10;             // aluOut
            dMemAddressSelect = 1'b1;           // {8'd0,iMemOut[11:4]};
            dMemWriteEn = 1'b1;
            dMemReadEn = 1'b1;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b0;
            iMemAddrAndPcInSelect = 3'b001;     // pcOut, pcPlusOne
            iMemReadEnable = 1'b1;
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end
        // [Type R-R]
        else if(iMemOut[7:3] > 5'b00000 && iMemOut[7:3] < 5'b01001 && iMemOut[2:0] == 3'b000) begin
            regFileSrc = 2'b00;                 // aluOut
            regFileOutBSelect = iMemOut[11:8];  // SSSS
            regFileWriteEnable = 1'b1;
            regFileIncPair = 1'b0;            
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;               // regFileOutA
            aluSrcBSelect = 2'b00;              // regFileOutB
            aluMode = iMemOut[6:3];
            dMemDataSelect = 2'b10;             // aluOut, doesnt really matter
            dMemAddressSelect = 1'b0;          // {regFileOutC,regFileOutB}, but doesnt really matter
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b1;
            iMemAddressSelect = 3'b001;         // pcOut
            iMemReadEnable = 1'b1;
            iMemAddrAndPcInSelect = 3'b001;     // pcPlusOne
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end
        else if(iMemOut[7:3] >= 5'b01001 && iMemOut[7:3] < 5'b00100 && iMemOut[2:0] == 3'b000)

        //[Type R-RP]
        else if(iMemOut[7:0] > 8'b00010100 && iMemOut[7:0] < 8'b00100010) begin
            regFileSrc = 2'b10;                                                     // regFileIn = dMemOut
            regFileOutBSelect = (iMemOut[11:9]*2);
            if(iMemOut[7:0] < 00011100) begin                                       // covers store
                regFileWriteEnable = 1'b0;
                dMemWriteEn = 1'b1;
                dMemReadEn = 1'b0;
                iMemReadEnable = 1'b1;
                pcWriteEn = 1'b1;
                nextState = 2'b00;
            end
            else begin                                                              // covers load
                if(state == 2'b00) begin
                    regFileWriteEnable = 1'b0;
                    iMemReadEnable = 1'b0;
                    pcWriteEn = 1'b0;
                    nextState = 2'b01;  // Move to next state
                end
                else(state == 2'b00) begin
                    regFileWriteEnable = 1'b1;
                    iMemReadEnable = 1'b1;
                    pcWriteEn = 1'b1;
                    nextState = 2'b00; 
                end
                dMemWriteEn = 1'b0;
                dMemReadEn = 1'b1;
            end
            if(iMemOut[7:0] == 8'b00011000 || iMemOut[7:0] == 8'b00011110) begin          // covers increment
                regFileIncPair = 1'b1;
                regFileDecPair = 1'b0;
            end
            else if(iMemOut[7:0] == 8'b00011010 || iMemOut[7:0] == 8'b00100000) begin     // covers decrement
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b1;
            end
            else begin                                                              // covers not increment and not decrement
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
            end
            aluSrcASelect = 1'b1:                                                   // regFileOutA
            aluSrcBSelect = 2'b00;                                                  // regFileOutB, but doesnt really matter
            aluMode = 4'b1101;                                                      // Pass A
            dMemDataSelect = 2'b10;                                                 // aluOut
            dMemAddressSelect = 2'b00;                                              // {regFileOutC,regFileOutB}
            statusRegSrcSelect = 2'b00;                                             // ALU flags out and save interrupt enable status
            carryFlagEnable = 1'b0;
            zeroFlagEnable = 1'b0;
            negativeFlagEnable = 1'b0;
            interruptEnableEnable = 1'b0;
            iMemAddressSelect = 3'b001;                                             // pcOut
            pcInSelect = 3'b001;                                                    // pcPlusOne
            nextMulti = 2'b00;
        end
        
        //[Type RP]
        else if(iMemOut[7:0] == 8'b00101110 || iMemOut[7:0] == 8'b00110000 || iMemOut[7:0] == 8'b00110010) begin
            regFileSrc = 2'b00;                   // aluOut, doesnt really matter
            regFileOutBSelect = 2'b00;            // regFileOutB, doesnt really matter
            regFileWriteEnable = 1'b0;
            if(iMemOut[7:0] == 8'b00101110) begin // IRP
                regFileIncPair = 1'b1;
                regFileDecPair = 1'b0;
                iMemAddressSelect = 3'b001:     // pcOut
                pcInSelect = 3'b001;            // pcPlusOne
            end
            else if(imemOut[7:0] == 8'b00110000) begin
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b1;
                iMemAddressSelect = 3'b001;     // pcOut
                pcInSelect = 3'b001;            // pcPlusOne
            end
            else begin
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
                if(jmp) begin
                    iMemAddressSelect = 3'b100;     // {regFileOutC, regFileOutB}
                    pcInSelect = 3'b100;            // {regFileOutC, regFileOutB} + 1
                end
                else begin
                    iMemAddressSelect = 3'b001;     // pcOut
                    pcInSelect = 3'b001;            // pcPlusOne
                end
            end
            aluSrcASelect = 1'b1;   // regFileOutA, doesnt really matter
            aluSrcBSelect = 2'b00;  // regFileOutB, doesnt really matter
            aluMode = 4'b0000;      // Pass B, doesnt really matter
            dMemDataSelect = 2'b10; // aluOut
            dMemAddressSelect = 2'b00;   // {regFileOutC,regFileOutB}, doesnt really matter
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00; // ALU flags out and save interrupt enable status
            carryFlagEnable = 1'b0;
            zeroFlagEnable = 1'b0;
            negativeFlagEnable = 1'b0;
            interruptEnableEnable = 1'b0;
            iMemReadEnable = 1'b1;
            pcWriteEn = 1'b1;
            nextState = 2'b00;
            nextMulti = 2'b00;
        end
        //[Type Absolute Address]
        else if(iMemOut[7:0] == 8'b00110100 || iMemOut[7:0] == 8'b00110110) begin
            regFileSrc = 2'b00;                   // aluOut, doesnt really matter
            regFileOutBSelect = 2'b00;            // regFileOutB, doesnt really matter
            regFileWriteEnable = 1'b0;
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;                 // regFileOutA, doesnt really matter
            aluSrcBSelect = 2'b00;                // regFileOutB, doesnt really matter
            aluMode = 4'b0000;                    // Pass B, doesnt really matter
            dMemDataSelect = 2'b10;               // aluOut, doesnt really matter
            dMemAddressSelect = 2'b00;            // {regFileOutC,regFileOutB}, doesnt really matter
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00;           // ALU flags out and save interrupt enable status
            carryFlagEnable = 1'b0;
            zeroFlagEnable = 1'b0;
            negativeFlagEnable = 1'b0;
            interruptEnableEnable = 1'b0;
            iMemAddressSelect = 3'b001;     // pcOut
            iMemReadEnable = 1'b1;
            pcInSelect = 3'b001;            // pcPlusOne
            pcWriteEn = 1'b1;
            if(jmp) begin
                nextMulti = iMemOut[2:1];
            end
            else begin
                nextMulti = 2'b00;
            end
            nextState = 2'b00;
        end
        // Type:  ret
        else if(iMemOut[7:0] == 8'b00111000) begin
            
        end
    end
end