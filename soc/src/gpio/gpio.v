module gpio(input wire clk,
            input wire [7:0] din,
            input wire [7:0] address,
            input wire w_en,
            input wire r_en,
            output reg [7:0] dout,
            output reg [7:0] dir = 0,
            output reg [7:0] port = 0,
            inout wire [7:0] pins
);  
    //*****************************************************
    parameter GPIO_ADDRESS = 8'h00;
    localparam DIR_ADDRESS = GPIO_ADDRESS;
    localparam PORT_ADDRESS = GPIO_ADDRESS + 1;
    localparam PINS_ADDRESS = GPIO_ADDRESS + 2;
    //*****************************************************
    always @(posedge clk) begin
        case(address)
            DIR_ADDRESS: begin
                if(w_en) begin
                    dir <= din;
                end
                if(r_en) begin
                    dout <= dir;
                end
            end
            PORT_ADDRESS: begin
                if(w_en) begin
                    port <= din;
                end
                if(r_en) begin
                    dout <= port;
                end
            end
            PINS_ADDRESS: begin
                if(r_en) begin
                    dout <= pins;
                end
            end
        endcase
    end
    //*****************************************************
endmodule