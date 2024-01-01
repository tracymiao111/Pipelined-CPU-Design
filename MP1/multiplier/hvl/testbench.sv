
`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
// initial $monitor("[student_testbench] dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// verify results of the multiplier
task check_results();
    itf.start <= 1'b0;
    for (int i = 0; i <= 255; ++i) begin
        for (int j = 0; j <= 255; ++j) begin
            @(tb_clk);
            itf.start        <= 1'b1;
            itf.multiplicand <= i;
            itf.multiplier   <= j;
            @(posedge itf.done);
            check_mult: assert (itf.product == i * j)
                else begin
                    $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
                    report_error (BAD_PRODUCT);
                end
        end
    end
endtask: check_results

//verify reset
task check_reset(op_e op_to_check);
    itf.multiplicand <= $urandom_range(0, 255);
    itf.multiplier   <= $urandom_range(0, 255);
    @(tb_clk);
    itf.start <= 1'b1;
    @(tb_clk);
    itf.start <= 1'b0;
    @(tb_clk iff (itf.mult_op == op_to_check)) begin
        reset();
        check_reset_op: assert (itf.rdy == 1'b1)
            else begin
                $error ("%0d: %0t: NOT_READY error detected for %s", `__LINE__, $time, op_to_check.name());
                report_error (NOT_READY);
            end
    end
endtask : check_reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error

initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    check_results();
    check_reset(SHIFT);
    check_reset(ADD);
    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
