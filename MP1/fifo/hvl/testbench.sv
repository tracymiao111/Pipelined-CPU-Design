`ifndef testbench
`define testbench


module testbench(fifo_itf itf);
import fifo_types::*;

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

task check_reset();
    @(tb_clk);
        assert (itf.rdy == 1'b1) else begin
            $error ("%0d: %0t: %s error detected", `__LINE__, $time, RESET_DOES_NOT_CAUSE_READY_O);
            report_error (RESET_DOES_NOT_CAUSE_READY_O);
        end
    @(tb_clk);
endtask: check_reset

task check_enq();
    itf.valid_i <= 1'b1;
    for (int i = 0; i <= CAP_P - 1; ++i) begin
        itf.data_i <= i;
        @(tb_clk);
        assert (itf.data_o == 0) else begin
            $error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
            report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end
    end
    itf.valid_i <= 1'b0;
    @(tb_clk);
endtask: check_enq

task check_deq();
    itf.yumi <= 1'b1;
    for (int i = 1; i <= CAP_P; ++i) begin
        assert (itf.data_o == (i - 1)) else begin
            $error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
            report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end
        @(tb_clk);
    end
    itf.yumi <= 1'b0;
endtask

task check_enq_deq();
    itf.valid_i <= 1'b1;
    for (int i = 0; i < CAP_P; i++) begin
        itf.data_i <= i;
        ##(1);
        itf.yumi <= 1'b1;
        ##(1);
        assert (itf.data_o == (((i + 1) / 2))) else begin
            $error ("%0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
            report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end
        itf.yumi <= 1'b0;
    end
    itf.valid_i <= 1'b0;
endtask

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    check_reset();
    check_enq();
    check_deq();
    reset();
    check_reset();
    check_enq_deq();
    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

