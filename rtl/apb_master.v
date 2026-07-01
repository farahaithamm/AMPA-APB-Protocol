module APB_MASTER #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32, 
                   parameter MEM_DEPTH = 128, localparam PSTRB_WIDTH = DATA_WIDTH/8)(
    input wire PCLK,
    input wire PRESETn,

    input wire [ADDR_WIDTH-1:0] addr,
    input wire sel, // 0 for slave0, 1 for slave1
    input wire transfer,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [PSTRB_WIDTH-1:0] strb,

    output reg [DATA_WIDTH-1:0] OUTDATA,

    // From slave
    input wire PREADY,
    input wire [DATA_WIDTH-1:0] PRDATA,
    input wire PSLVERR,

    // To slave
    output wire [ADDR_WIDTH-1:0] PADDR,
    output wire [1:0] PSEL, // PSEL[0] for slave0, PSEL[1] for slave1
    output reg PENABLE,
    output wire PWRITE, // 1 write, 0 read
    output wire [DATA_WIDTH-1:0] PWDATA,
    output wire [PSTRB_WIDTH-1:0] PSTRB
);

    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    reg [1:0] cs, ns;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) cs <= IDLE;
        else cs <= ns;
    end

    always @(*) begin
        case (cs)
            IDLE: begin
                if(transfer) ns = SETUP;
                else ns = IDLE;
            end
            SETUP: begin
                ns = ACCESS;
            end
            ACCESS: begin
                if (PREADY) ns = (transfer) ? SETUP : IDLE;
                else ns = ACCESS;
            end
            default: ns = IDLE;
        endcase
    end

    always @(*) begin
        PENABLE = 0;
        OUTDATA = 0;
        if(cs == ACCESS) begin
            PENABLE = 1'b1;
            if(PREADY && !PSLVERR && !wr_en) OUTDATA = PRDATA;
        end
    end

    assign PSEL = {sel, ~sel};
    assign PADDR = addr;
    assign PWRITE = wr_en;
    assign PWDATA = wdata;
    assign PSTRB = strb;

endmodule
