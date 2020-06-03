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
    reg [7:0] registerFile [0:15];
    integer i;
    initial begin
        for(i = 0; i < 15; i = i + 1) begin
            registerFile[i] = 8'd0;
        end
    end

    always @(posedge clk) begin
        if(write_en) begin
            registerFile[inSelect] <= in;
        end
        else if(inc) begin
            {registerFile[(outBselect*2) + 1],registerFile[outBselect*2]} = {registerFile[(outBselect*2) + 1],registerFile[outBselect]} + 1;
        end
        else if(dec) begin
            {registerFile[(outBselect*2) + 1],registerFile[outBselect*2]} = {registerFile[(outBselect*2) + 1],registerFile[outBselect]} - 1;
        end
    end

    assign  outA = registerFile[inSelect];
    assign  outB = registerFile[outBselect];
    assign  outC = registerFile[outBselect + 1];

endmodule