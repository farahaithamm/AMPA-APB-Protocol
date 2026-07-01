module APV_WRAPPER_tb();
    parameter ADDR_WIDTH = 32; parameter DATA_WIDTH = 32; 
    parameter MEM_DEPTH = 128; localparam PSTRB_WIDTH = DATA_WIDTH/8;
    
    logic PCLK, PRESETn;
    logic [ADDR_WIDTH-1:0] addr;
    logic sel, transfer, wr_en;
    logic [DATA_WIDTH-1:0] wdata;
    logic [PSTRB_WIDTH-1:0] strb;
    logic [DATA_WIDTH-1:0] OUTDATA;

    logic pslverr_sampled;

    APB_WRAPPER dut(
        .PCLK(PCLK), .PRESETn(PRESETn),
        .addr(addr), .sel(sel), 
        .transfer(transfer), .wr_en(wr_en), 
        .wdata(wdata), .strb(strb), .OUTDATA(OUTDATA)
    );

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    clocking cb_apb @(posedge PCLK);
        default input #1step output #0;
        input PRESETn, OUTDATA;
        output addr, sel, transfer, wr_en, wdata, strb;
    endclocking

    always @(posedge PCLK) begin
        #1step;
        pslverr_sampled = dut.PSLVERR;
    end

    initial begin
        $readmemh("mem.dat", dut.slave0.mem);
        $readmemh("mem.dat", dut.slave1.mem);

        assert_reset();

        $display("TEST(1) -- SLAVE 0");
        write_data(32'd111, 1'b0, 32'h12345678, 4'b0011);
        read_data(32'd111, 1'b0);
        check_output(32'h00005678);

        $display("TEST(2) -- SLAVE 0, WRITE WRONG ADDR");
        write_data(32'd1000, 1'b0, 32'h12345678, 4'b0011);
        if(pslverr_sampled != 1'b1) $display("ERROR AT TIME %0t WHERE PSLVERR SHOULD BE HIGH", $time);
        else $display("PASS");

        $display("TEST(3) -- SLAVE 0, READ WRONG ADDR");
        read_data(32'd1234, 1'b0);
        if(pslverr_sampled != 1'b1) $display("ERROR AT TIME %0t WHERE PSLVERR SHOULD BE HIGH", $time);
        else $display("PASS");
        check_output(32'h00000000);

        $display("TEST(4) -- SLAVE 1");
        write_data(32'd12, 1'b1, 32'h59843126, 4'b1010);
        read_data(32'd12, 1'b1);
        check_output(32'h59003100);

        $display("TEST(5) -- SLAVE 1, WRITE WRONG ADDR");
        write_data(32'd900, 1'b1, 32'h59843126, 4'b1010);
        if(pslverr_sampled != 1'b1) $display("ERROR AT TIME %0t WHERE PSLVERR SHOULD BE HIGH", $time);
        else $display("PASS");

        $display("TEST(6) -- SLAVE 1, READ ON WRONG ADDR");
        read_data(32'd9000, 1'b1);
        if(pslverr_sampled != 1'b1) $display("ERROR AT TIME %0t WHERE PSLVERR SHOULD BE HIGH", $time);
        else $display("PASS");
        check_output(32'h00000000);

        $display("TEST(7) -- SLAVE 0, WRITE READ 2 HIGH TRANSFER");
        write_read_data(32'd20, 1'b0, 32'h98765432, 4'b1100);
        check_output(32'h98760000);
        $stop;

    end

    task assert_reset();
        PRESETn = 0;
        addr = 0;
        sel = 0;
        transfer = 0;
        wr_en = 0;
        wdata = 0;
        strb = 0;
        @(cb_apb);
        PRESETn = 1;
    endtask 

    task write_data(input logic [ADDR_WIDTH-1:0] addr_value,
                    input logic sel_value,
                    input logic [DATA_WIDTH-1:0] wdata_value,
                    input logic [PSTRB_WIDTH-1:0] strb_value);
        
        cb_apb.addr <= addr_value;
        cb_apb.sel <= sel_value;
        cb_apb.transfer <= 1;
        cb_apb.wr_en <= 1;
        cb_apb.wdata <= wdata_value;
        cb_apb.strb <= strb_value;
        @(cb_apb);

        cb_apb.transfer <= 0;
        repeat(2) @(cb_apb);
    endtask

    task write_read_data(input logic [ADDR_WIDTH-1:0] addr_value,
                    input logic sel_value,
                    input logic [DATA_WIDTH-1:0] wdata_value,
                    input logic [PSTRB_WIDTH-1:0] strb_value);
        
        cb_apb.addr <= addr_value;
        cb_apb.sel <= sel_value;
        cb_apb.transfer <= 1;
        cb_apb.wr_en <= 1;
        cb_apb.wdata <= wdata_value;
        cb_apb.strb <= strb_value;
        @(cb_apb);

        repeat(2) @(cb_apb);

        cb_apb.wr_en <= 0;
        @(cb_apb);

        cb_apb.transfer <= 0;
        @(cb_apb);

    endtask 

    task read_data(input logic [ADDR_WIDTH-1:0] addr_value,
                    input logic sel_value);
        cb_apb.addr <= addr_value;
        cb_apb.sel <= sel_value;
        cb_apb.transfer <= 1;
        cb_apb.wr_en <= 0;
        @(cb_apb);

        cb_apb.transfer <= 0;
        repeat(2) @(cb_apb);
    endtask

    task check_output(input logic[DATA_WIDTH-1:0] out_exp);
        if (cb_apb.OUTDATA != out_exp) $display("ERROR AT TIME %0t, OUTDATA = %h, EXP = %h", $time, OUTDATA, out_exp);
        else $display("PASS");
    endtask

endmodule