module APB_WRAPPER #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32, 
             parameter MEM_DEPTH = 128, localparam PSTRB_WIDTH = DATA_WIDTH/8)(
    input wire PCLK,
    input wire PRESETn,

    input wire [ADDR_WIDTH-1:0] addr,
    input wire sel, // 0 for slave0, 1 for slave1
    input wire transfer,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [PSTRB_WIDTH-1:0] strb,
    
    output wire [DATA_WIDTH-1:0] OUTDATA
);

    wire PREADY, PREADY0, PREADY1;
    wire [DATA_WIDTH-1:0] PRDATA, PRDATA0, PRDATA1;
    wire PSLVERR, PSLVERR0, PSLVERR1;

    wire [ADDR_WIDTH-1:0] PADDR;
    wire [1:0] PSEL;
    wire PENABLE;
    wire PWRITE;
    wire [DATA_WIDTH-1:0] PWDATA;
    wire [PSTRB_WIDTH-1:0] PSTRB;

    APB_MASTER master(
        .PCLK(PCLK), .PRESETn(PRESETn), .addr(addr),
        .sel(sel), .transfer(transfer), .wr_en(wr_en),
        .wdata(wdata), .strb(strb), .OUTDATA(OUTDATA),
        .PREADY(PREADY), .PRDATA(PRDATA), .PSLVERR(PSLVERR),
        .PADDR(PADDR), .PSEL(PSEL), .PENABLE(PENABLE),
        .PWRITE(PWRITE), .PWDATA(PWDATA), .PSTRB(PSTRB)
    );

    APB_SLAVE slave0(
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PADDR(PADDR), .PSEL(PSEL[0]), .PENABLE(PENABLE),
        .PWRITE(PWRITE), .PWDATA(PWDATA), .PSTRB(PSTRB),
        .PREADY(PREADY0), .PRDATA(PRDATA0), .PSLVERR(PSLVERR0)
    );


    APB_SLAVE slave1(
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PADDR(PADDR), .PSEL(PSEL[1]), .PENABLE(PENABLE),
        .PWRITE(PWRITE), .PWDATA(PWDATA), .PSTRB(PSTRB),
        .PREADY(PREADY1), .PRDATA(PRDATA1), .PSLVERR(PSLVERR1)
    );

    assign PREADY = (sel) ? PREADY1 : PREADY0;
    assign PRDATA = (sel) ? PRDATA1 : PRDATA0;
    assign PSLVERR = (sel) ? PSLVERR1 : PSLVERR0;

endmodule