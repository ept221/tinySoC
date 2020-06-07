module regFile(input wire [3:0] inSelect,
               input wire [3:0] outBselect,
               input wire [7:0] in,
               input wire write_en,
               input wire inc,
               input wire dec,
               input wire clk,
               output wire [7:0] outA,
               output wire [7:0] outB,
               output wire [7:0] outC
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
        if(inc && (~write_en || (write_en && ~(inSelect == outBselect)))) begin
            {rFile[(outBselect*2) + 1],rFile[outBselect*2]} <= {rFile[(outBselect*2) + 1],rFile[outBselect]} + 1;
        end
        else if(dec && (~write_en || (write_en && ~(inSelect == outBselect)))) begin
            {rFile[(outBselect*2) + 1],rFile[outBselect*2]} <= {rFile[(outBselect*2) + 1],rFile[outBselect]} - 1;
        end
    end

    assign  outA = rFile[inSelect];
    assign  outB = rFile[outBselect];
    assign  outC = rFile[outBselect + 1];

endmodule