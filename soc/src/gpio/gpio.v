module gpio(input wire clk,
            input wire [7:0] din,
            input wire [7:0] address,
            input wire w_en,
            input wire r_en,
            output reg [7:0] dout
);  
    //*****************************************************
    parameter GPIO_ADDRESS = 8'h00;
    parameter DIR_ADDRESS = GPIO_ADDRESS;
    parameter PORT_ADDRESS = GPIO_ADDRESS + 1;
    parameter PINS_ADDRESS = GPIO_ADDRESS + 2;
    //*****************************************************
    reg [7:0] dir = 0;
    reg [7:0] port = 0;
    wire [7:0] pins;
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
                if(w_en) begin
                    pins <= din;
                end
                if(r_en) begin
                    dout <= pins;
                end
            end
        endcase
    end
    //*****************************************************
endmodule