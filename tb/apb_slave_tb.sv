module APV_SLAVE_tb();
    parameter ADDR_WIDTH = 32; parameter DATA_WIDTH = 32; 
    parameter MEM_DEPTH = 128; localparam PSTRB_WIDTH = DATA_WIDTH/8;
    logic PCLK, PRESETn;
    logic [ADDR_WIDTH-1:0] PADDR;
    logic PSEL, PENABLE, PWRITE;
    logic [DATA_WIDTH-1:0] PWDATA;
    logic [PSTRB_WIDTH-1:0] PSTRB;

    logic PREADY;
    logic [DATA_WIDTH-1:0] PRDATA;
    logic PSLVERR;

    logic [DATA_WIDTH-1:0] ref_mem [MEM_DEPTH-1:0];
    logic pready_exp, pslverr_exp;
    logic [DATA_WIDTH-1:0] prdata_exp;

    APB_SLAVE dut(
        .PCLK(PCLK), 
        .PRESETn(PRESETn), 
        .PADDR(PADDR), 
        .PSEL(PSEL), 
        .PENABLE(PENABLE), 
        .PWRITE(PWRITE),
        .PWDATA(PWDATA), 
        .PSTRB(PSTRB), 
        .PREADY(PREADY), 
        .PRDATA(PRDATA), 
        .PSLVERR(PSLVERR)
    );

    initial begin
        PCLK <= 0;
        forever #5 PCLK = ~PCLK;
    end

    clocking cb_apb_slave @(posedge PCLK);
        input PRESETn, PREADY, PSLVERR, PRDATA;
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB;
    endclocking

    initial begin
        $readmemh("mem.dat", dut.mem);
        $readmemh("mem.dat", ref_mem);

        assert_reset();

        repeat(20) write_data();
        repeat(20) read_data();
        repeat(20) read_write_data();

        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = 200;
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        if (PSLVERR != 1) 
            $display("WRITE: ERROR AT ADDR > 127 CASE");
        else $display("PASS");

        PSEL = 0;
        PENABLE = 0;
        @(cb_apb_slave);

        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = 200;
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        if (PSLVERR != 1) 
            $display("WRITE: ERROR AT ADDR > 127 CASE");
        else $display("PASS");

        PSEL = 0;
        PENABLE = 0;
        @(cb_apb_slave);

        PSEL = 1;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 5000;
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        if (PSLVERR != 1) 
            $display("READ: ERROR AT ADDR > 127 CASE");
        else $display("PASS");

        PSEL = 0;
        PENABLE = 0;
        @(cb_apb_slave);

        assert_reset();
        $stop;

    end

    task assert_reset();
        PRESETn = 0;
        PADDR = 0;
        PSEL = 0;
        PENABLE = 0; 
        PWRITE = 0;
        PWDATA = 0;
        PSTRB = 0;
        @(cb_apb_slave);
        PRESETn = 1;
    endtask

    task write_data();
        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = $urandom_range(0, 127);
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        ref_model();
        if (dut.mem[PADDR] != ref_mem[PADDR] || pslverr_exp != PSLVERR || pready_exp != PREADY) 
            $display("WRITE: ERROR at address %0d at time %0t", PADDR, $time);
        else $display("PASS WRITE");

        PSEL = 0;
        PENABLE = 0;
        @(cb_apb_slave);
    endtask

    task read_data();
        PSEL = 1;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = $urandom_range(0, 127);
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        ref_model();
        if (prdata_exp != PRDATA || pslverr_exp != PSLVERR || pready_exp != PREADY) 
            $display("READ: ERROR at address %0d at time %0t", PADDR, $time);
        else $display("PASS READ");

        PSEL = 0;
        PENABLE = 0;
        @(cb_apb_slave);
    endtask

    task read_write_data();
        PSEL = 1;
        PENABLE = 0;
        PWRITE = $random;
        PADDR = $urandom_range(0, 127);
        PSTRB = $urandom_range(0, 15);
        PWDATA = $random;
        @(cb_apb_slave);

        PENABLE = 1;
        @(cb_apb_slave);

        ref_model();
        if(PWRITE) begin
            if (dut.mem[PADDR] != ref_mem[PADDR] || pslverr_exp != PSLVERR || pready_exp != PREADY) 
            $display("WRITE: ERROR at address %0d at time %0t", PADDR, $time);
        else $display("PASS WRITE");
        end
        else begin
            if (prdata_exp != PRDATA || pslverr_exp != PSLVERR || pready_exp != PREADY) 
            $display("READ: ERROR at address %0d at time %0t", PADDR, $time);
        else $display("PASS READ");
        end
        
        PSEL = 0;
        PENABLE = 0;
    endtask

    task ref_model;
        pslverr_exp = 0;
        prdata_exp = 0;
        if (PSEL && PENABLE) begin
            if (PADDR >= MEM_DEPTH) begin
                pslverr_exp = 1;
            end
            else begin
                pslverr_exp = 0;
                if (PWRITE) begin
                    for (int i=0; i < PSTRB_WIDTH; i++) begin
                        if (PSTRB[i]) ref_mem[PADDR][i*8 +: 8] = PWDATA[i*8 +: 8];
                    end
                end
                else prdata_exp = ref_mem[PADDR];
            end
            pready_exp = 1;
        end

    endtask
    
endmodule