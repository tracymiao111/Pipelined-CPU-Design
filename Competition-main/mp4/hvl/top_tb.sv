import "DPI-C" function string getenv(input string env_name);

module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_period_ps = getenv("CLOCK_PERIOD_PS").atoi() / 2;

    bit clk;
    initial clk = 1'b1;
    always #(clock_period_ps) clk = ~clk;

    bit rst;

    int timeout = 10000000; // in cycles, change according to your needs

    //  CPU metrics
    logic [63:0] dmem_stall_count;
    logic [63:0] imem_stall_count;
    logic [63:0] pipeline_flushing;
    logic get_is_branch;

    // dcache metrics
    logic [63:0] dcache_miss;
    logic [63:0] dcache_evict;
    logic [63:0] allocate_cycle;
    logic [63:0] write_back_cycle;
    logic [63:0] dcache_nonhit_total_cycles;
    logic miss_flag, evict_flag;
    

    // CP1
    // mem_itf magic_itf_i(.*);
    // mem_itf magic_itf_d(.*);
    // magic_dual_port magic_dual_port(.itf_i(magic_itf_i), .itf_d(magic_itf_d));

    // CP2
    bmem_itf bmem_itf(.*);
    burst_memory burst_memory(.itf(bmem_itf));

    mon_itf mon_itf(.*);    
    monitor monitor(.itf(mon_itf));

    mp4 dut(
        .clk          (clk),
        .rst          (rst),

        // Use these for CP1
        // .imem_address  (magic_itf_i.addr),
        // .imem_read     (magic_itf_i.read),
        // .imem_rdata    (magic_itf_i.rdata),
        // .imem_resp     (magic_itf_i.resp),
        // .dmem_address  (magic_itf_d.addr),
        // .dmem_read     (magic_itf_d.read),
        // .dmem_write    (magic_itf_d.write),
        // .dmem_wmask    (magic_itf_d.wmask),
        // .dmem_rdata    (magic_itf_d.rdata),
        // .dmem_wdata    (magic_itf_d.wdata),
        // .dmem_resp     (magic_itf_d.resp)

        // Use these for CP2+
        .bmem_address (bmem_itf.addr),
        .bmem_read    (bmem_itf.read),
        .bmem_write   (bmem_itf.write),
        .bmem_rdata   (bmem_itf.rdata),
        .bmem_wdata   (bmem_itf.wdata),
        .bmem_resp    (bmem_itf.resp)
    );

    always_comb begin
        mon_itf.valid     = dut.monitor_valid;
        mon_itf.order     = dut.monitor_order;
        mon_itf.inst      = dut.monitor_inst;
        mon_itf.rs1_addr  = dut.monitor_rs1_addr;
        mon_itf.rs2_addr  = dut.monitor_rs2_addr;
        mon_itf.rs1_rdata = dut.monitor_rs1_rdata;
        mon_itf.rs2_rdata = dut.monitor_rs2_rdata;
        mon_itf.rd_addr   = dut.monitor_rd_addr;
        mon_itf.rd_wdata  = dut.monitor_rd_wdata;
        mon_itf.pc_rdata  = dut.monitor_pc_rdata;
        mon_itf.pc_wdata  = dut.monitor_pc_wdata;
        mon_itf.mem_addr  = dut.monitor_mem_addr;
        mon_itf.mem_rmask = dut.monitor_mem_rmask;
        mon_itf.mem_wmask = dut.monitor_mem_wmask;
        mon_itf.mem_rdata = dut.monitor_mem_rdata;
        mon_itf.mem_wdata = dut.monitor_mem_wdata;
    end

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end

    final begin
        $display("%c[0;32m",27);
        $display("\n============= Memory Stalls =============");
        $display("imem stall total cycles: %0d", imem_stall_count);
        $display("dmem stall total cycles: %0d\n", dmem_stall_count);
        $display("============= Pipeline flush =============");
        $display("pipline flush total count: %0d", pipeline_flushing);
        
        $display("%c[0;36m", 27);
        $display("============= Data Cache =============");
        $display("Data cache miss total count: %0d", dcache_miss);
        $display("Data cache evict total count: %0d\n", dcache_evict);
        $display("Data cache allocate total cycles: %0d", allocate_cycle);
        $display("Data cache writeback total cycles: %0d\n", write_back_cycle);
        $display("Data cache total nonhit-waiting cycles: %0d\n", dcache_nonhit_total_cycles);
        $write("%c[0m",27);
    end

    always @(posedge clk) begin
        if (mon_itf.halt) begin
            $finish;
        end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        if (mon_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        // Comment this for CP2+
        // if (magic_itf_i.error != 0 || magic_itf_d.error != 0) begin
        //     repeat (5) @(posedge clk);
        //     $finish;
        // end
        // Uncomment this for CP2+
        if (bmem_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        timeout <= timeout - 1;
    end

    // keep track of stalling and jumping
    always_ff @(posedge clk) begin
        if(rst) begin
            dmem_stall_count <= '0;
            imem_stall_count <= '0;
            pipeline_flushing <= '0;
            get_is_branch <= '0;
        end
        else begin
            if(dut.cpu.imem_stall == 1'b1) begin
                imem_stall_count <= imem_stall_count + 1'b1;
            end 
                
            if(dut.cpu.dmem_stall == 1'b1) begin
                dmem_stall_count <= dmem_stall_count + 1'b1;
            end
            
            // counting number of times that the pipeline is flushed due to branch and jump
            if(get_is_branch == 1'b0) begin
                if(dut.cpu.ex_to_mem.branch_take == 1'b1) begin
                    get_is_branch <= 1'b1;
                    pipeline_flushing <= pipeline_flushing + 1'b1;
                end
            end
            else begin
                if(dut.cpu.ex_to_mem.branch_take == 1'b0) begin
                    get_is_branch <= 1'b0;
                end
            end
        end
    end

    // cache metrics
    always_ff @(posedge clk) begin
        if(rst)begin
            dcache_miss <= '0;
            dcache_evict <= '0;
            miss_flag <= '0;
            evict_flag <= '0;
            allocate_cycle <= '0;
            write_back_cycle  <= '0;
            dcache_nonhit_total_cycles <= '0;
        end
        else begin

            if(dut.dcache.control.state.name() == "ALLOCATE") begin
                allocate_cycle <= allocate_cycle + 1'b1;
            end

            if(dut.dcache.control.state.name() == "WRITE_BACK") begin
                write_back_cycle <= write_back_cycle + 1'b1;
            end

            if(dut.dcache.control.state.name() inside {"ALLOCATE", "WRITE_BACK"}) begin
                dcache_nonhit_total_cycles <= dcache_nonhit_total_cycles + 1'b1;
            end


            if(miss_flag == 1'b0) begin
                if(dut.dcache.control.is_allocate == 1'b1) begin  // a miss
                    dcache_miss <= dcache_miss + 1'b1;
                    miss_flag <= 1'b1;
                end 
            end
            else if(dut.dcache.control.is_allocate == 1'b0) begin
                miss_flag <= '0;
            end

            if(evict_flag == 1'b0) begin 
                if(dut.dcache.control.state.name() == "WRITE_BACK") begin
                    dcache_evict <= dcache_evict + 1'b1;
                    evict_flag <= 1'b1;
                end 
            end
            else if(dut.dcache.control.state.name() != "WRITE_BACK") begin
                evict_flag <= 1'b0;
            end

            
        end
    end 

endmodule
