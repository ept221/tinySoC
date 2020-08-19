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
    // Construct the register file and initialize it to zero
    reg [7:0] rFile [0:15];
    integer i;
    initial begin
        for(i = 0; i < 16; i = i + 1) begin
            rFile[i] = 8'd0;
        end
    end
    
    always @(posedge clk) begin
        if(write_en) begin
            rFile[inSelect] <= in;
        end
        if(inc&& (~write_en || (write_en && ~(inSelect == outBselect)))) begin
            case(outBselect)
            4'b0000:    {rFile[1],rFile[0]} <= {rFile[1],rFile[0]} + 16'b1;
            4'b0010:    {rFile[3],rFile[2]} <= {rFile[3],rFile[2]} + 16'b1;
            4'b0100:    {rFile[5],rFile[4]} <= {rFile[5],rFile[4]} + 16'b1;
            4'b0110:    {rFile[7],rFile[6]} <= {rFile[7],rFile[6]} + 16'b1;
            4'b1000:    {rFile[9],rFile[8]} <= {rFile[9],rFile[8]} + 16'b1;
            4'b1010:    {rFile[11],rFile[10]} <= {rFile[11],rFile[10]} + 16'b1;
            4'b1100:    {rFile[13],rFile[12]} <= {rFile[13],rFile[12]} + 16'b1;
            4'b1110:    {rFile[15],rFile[14]} <= {rFile[15],rFile[14]} + 16'b1;
            endcase
        end
        else if(dec && (~write_en || (write_en && ~(inSelect == outBselect)))) begin
            case(outBselect)
            4'b0000:    {rFile[1],rFile[0]} <= {rFile[1],rFile[0]} - 16'b1;
            4'b0010:    {rFile[3],rFile[2]} <= {rFile[3],rFile[2]} - 16'b1;
            4'b0100:    {rFile[5],rFile[4]} <= {rFile[5],rFile[4]} - 16'b1;
            4'b0110:    {rFile[7],rFile[6]} <= {rFile[7],rFile[6]} - 16'b1;
            4'b1000:    {rFile[9],rFile[8]} <= {rFile[9],rFile[8]} - 16'b1;
            4'b1010:    {rFile[11],rFile[10]} <= {rFile[11],rFile[10]} - 16'b1;
            4'b1100:    {rFile[13],rFile[12]} <= {rFile[13],rFile[12]} - 16'b1;
            4'b1110:    {rFile[15],rFile[14]} <= {rFile[15],rFile[14]} - 16'b1;
            endcase
        end
    end

    assign  outA = rFile[inSelect];
    assign  outB = rFile[outBselect];

    always @(*) begin
        case(outBselect)
        4'b0000:    outC = rFile[1];
        4'b0010:    outC = rFile[3];
        4'b0100:    outC = rFile[5];
        4'b0110:    outC = rFile[7];
        4'b1000:    outC = rFile[9];
        4'b1010:    outC = rFile[11];
        4'b1100:    outC = rFile[13];
        4'b1110:    outC = rFile[15];
        default     outC = 0;
        endcase
    end

endmodule