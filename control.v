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
wire [2:0] iMemAddrSelect;
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
            iMemAddrSelect = 3'b001;
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
            iMemAddrSelect = 3'b001;     // pcOut, pcPlusOne
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
            iMemAddrSelect = 3'b001;     // pcOut, pcPlusOne
            iMemReadEnable = 1'b1;
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end
        // [Type R-R] and [Type R]
        else if(iMemOut[7:3] > 5'b00000 && iMemOut[7:3] < 5'b01101 && iMemOut[2:0] == 3'b000) begin
            regFileSrc = 2'b00;                 // aluOut
            regFileOutBSelect = iMemOut[11:8];  // SSSS, or in the case of Type R, just 0000
            regFileWriteEnable = 1'b1;
            regFileIncPair = 1'b0;            
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b1;               // regFileOutA
            aluSrcBSelect = 2'b00;              // regFileOutB
            aluMode = iMemOut[6:3];
            dMemDataSelect = 2'b10;             // aluOut, doesnt really matter
            dMemAddressSelect = 1'b0;           // {regFileOutC,regFileOutB}, but doesnt really matter
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b1;
            iMemAddressSelect = 3'b001;         // pcOut
            iMemReadEnable = 1'b1;
            iMemAddrSelect = 3'b001;     // pcPlusOne
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end
        // [Type R-RP]
        else if(iMemOut[7:3] >= 5'b01101 && iMemOut[7:3] < 5'b10011 && iMemOut[2:0] == 3'b000) begin
            regFileSrc = 2'b00;                         // aluOut
            regFileOutBSelect = (iMemOut[11:9]*2);      // PPP
            regFileWriteEnable = iMemOut[7];
            aluSrcASelect = 1'b1;               // regFileOutA
            aluSrcBSelect = 2'b00;              // regFileOutB, doesnt really matter
            aluMode = 4'b1101;                  // Pass A
            dMemDataSelect = 2'b10;             // aluOut
            dMemAddressSelect = 1'b0;           // {regFileOutC,regFileOutB}
            dMemWriteEn = ~iMemOut[7];
            dMemReadEn = iMemOut[7];
            if(iMemOut[7:3] == 01101 || iMemOut[7:3] == 10000) begin
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b0;
            end
            else if(iMemOut[7:3] == 01110 || iMemOut[7:3] == 10001) begin
                regFileIncPair = 1'b1;
                regFileDecPair = 1'b0;
            end
            else begin
                regFileIncPair = 1'b0;
                regFileDecPair = 1'b1;
            end
        end
                  
wire dMemReadEn;
wire [1:0] statusRegSrcSelect;
wire flagEnable;
wire [2:0] iMemAddrSelect;
wire iMemReadEnable;
wire pcWriteEn;

        // PUS
        else if(iMemOut[7:3] == 5'b11001 && iMemOut[2:0] == 3'b000) begin
            regFileSrc = 2'b00;                 // aluOut, doesnt really matter
            regFileOutBSelect = 4'b1110;        // lower SP reg
            regFileWriteEnable = 1'b0;
            regFileIncPair = 1'b0;
            regFileDecPair = 1'b1;
            aluSrcASelect = 1'b0;               // From zero-extended status register
            aluSrcBSelect = 2'b00;              // regFileOutB, doesnt really matter
            aluMode = 4'b1101;                  // pass A
            dMemDataSelect = 2'b10;             // aluOut
            dMemAddressSelect = 1'b0;           // {regFileOutC,regFileOutB}
            dMemWriteEn = 1'b1;
            dMemReadEn = 1'b0;
            statusRegSrcSelect = 2'b00;         // ALU flags out and save interrupt enable status
            flagEnable = 1'b0;
            iMemAddrSelect = 3'b001;     // pcPlusOne
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end
        // POS
        else if(iMemOut[7:3] == 5'b11010 && iMemOut[2:0] == 3'b000) begin
            regFileSrc = 2'b00;                 // aluOut, doesnt really matter
            regFileOutBSelect = 4'b1110;        // lower SP reg
            regFileWriteEnable = 1'b0;
            regFileIncPair = 1'b1;
            regFileDecPair = 1'b0;
            aluSrcASelect = 1'b0;               // From zero-extended status register, doesnt really matter
            aluSrcBSelect = 2'b00;              // regFileOutB, doesnt really matter
            aluMode = 4'b1101;                  // pass A
            dMemDataSelect = 2'b10;             // aluOut, doesnt really matter
            dMemAddressSelect = 1'b0;           // {regFileOutC,regFileOutB}
            dMemWriteEn = 1'b0;
            dMemReadEn = 1'b1;
            statusRegSrcSelect = 2'b10;         // dMemOut[3:0]
            flagEnable = 1'b1;
            iMemAddrSelect = 3'b001;     // pcPlusOne
            pcWriteEn = 1'b1;
            nextState = 3'b000;
        end                    
    end
end