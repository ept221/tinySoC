module regFile(input wire [3:0] inSelect,
               input wire [3:0] outBselect,
               input wire [7:0] in,
               input wire write_en,
               input wire inc,
               input wire dec,
               input wire clk,
               output wire [7:0] outA,
               output wire [7:0] outB,
               output reg [7:0] outC
);
    //****************************************************************************************
    // Construct the register file and initialize it to zero
    reg [7:0] rFile [0:15];
    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) begin
            rFile[i] = 8'd0;
        end
    end
    //****************************************************************************************
    always @(posedge clk) begin
        if(write_en) begin
            rFile[inSelect] <= in;
        end
        if((inc || dec) && (~write_en || (write_en && ~(inSelect == outBselect)))) begin
            case(outBselect)
            4'b0000:    {rFile[1],rFile[0]} <= result;
            4'b0010:    {rFile[3],rFile[2]} <= result;
            4'b0100:    {rFile[5],rFile[4]} <= result;
            4'b0110:    {rFile[7],rFile[6]} <= result;
            4'b1000:    {rFile[9],rFile[8]} <= result;
            4'b1010:    {rFile[11],rFile[10]} <= result;
            4'b1100:    {rFile[13],rFile[12]} <= result;
            4'b1110:    {rFile[15],rFile[14]} <= result;
            endcase
        end
    end

    reg [15:0] inc_or_dec;
    reg [15:0] pair;
    reg [15:0] result;
    always @(*) begin
        result = pair + inc_or_dec;
        if(inc) begin
            inc_or_dec = 16'h0001;
        end
        else if(dec) begin
            inc_or_dec = 16'hffff;
        end
        else begin
            inc_or_dec = 16'h0000;
        end
    end
    //****************************************************************************************
    assign  outA = rFile[inSelect];
    assign  outB = rFile[outBselect];

    always @(*) begin
        case(outBselect)
        4'b0000: begin
            pair = {rFile[1],rFile[0]};
            outC = rFile[1];
        end
        4'b0010: begin
            pair = {rFile[3],rFile[2]};
            outC = rFile[3];
        end    
        4'b0100: begin
            pair = {rFile[5],rFile[4]};
            outC = rFile[5];
        end    
        4'b0110: begin
            pair = {rFile[7],rFile[6]};
            outC = rFile[7]; 
        end
        4'b1000: begin
            pair = {rFile[9],rFile[8]};
            outC = rFile[9];
        end    
        4'b1010: begin
            pair = {rFile[11],rFile[10]};
            outC = rFile[11];
        end
        4'b1100: begin
            pair = {rFile[13],rFile[12]};
            outC = rFile[13]; 
        end
        4'b1110: begin
            pair = {rFile[15],rFile[14]};
            outC = rFile[15];
        end
        default begin
            pair = 0;
            outC = 0;
        end
        endcase
    end
    //****************************************************************************************
endmodule