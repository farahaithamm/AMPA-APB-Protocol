module APB_SLAVE #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32, 
                   parameter MEM_DEPTH = 128, localparam PSTRB_WIDTH = DATA_WIDTH/8)(
    input wire PCLK,
    input wire PRESETn,

    // From master
    input wire [ADDR_WIDTH-1:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE, // 1 write, 0 read
    input wire [DATA_WIDTH-1:0] PWDATA,
    input wire [PSTRB_WIDTH-1:0] PSTRB,

    // To master
    output wire PREADY,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output wire PSLVERR
);
    reg [DATA_WIDTH-1:0] mem [MEM_DEPTH-1:0];
    reg [DATA_WIDTH-1:0] mask;

    integer i;
    always @(*) begin
        mask = '0;
        for(i = 0; i < PSTRB_WIDTH; i = i+1)
            mask[(i*8) +: 8] = {8{PSTRB[i]}};
    end

    integer j;
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            for(j = 0; j < MEM_DEPTH ; j = j+1) mem[j] <=0;
        end
        else if(PSEL && PENABLE && !PSLVERR && PWRITE) begin
            mem[PADDR] <= (mem[PADDR] & ~mask) | (mask & PWDATA);
        end
    end

    always @(*) begin
        if(PSEL && PENABLE && !PWRITE && !PSLVERR) PRDATA = mem[PADDR];
        else PRDATA = 0;
    end

    assign PREADY = (PSEL && PENABLE);
    assign PSLVERR = (PSEL && PENABLE && (PADDR >= MEM_DEPTH));

endmodule