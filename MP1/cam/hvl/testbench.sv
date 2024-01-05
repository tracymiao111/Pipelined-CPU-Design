module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
    itf.rw_n    <= 1'b0;
    itf.val_i   <= val;
    itf.key     <= key;
    @(tb_clk);
    itf.valid_i <= 1'b1;
endtask

task read(input key_t key, output val_t val);
    itf.rw_n    <= 1'b1;
    itf.key     <= key;
    val         <= itf.val_o;
    @(tb_clk);
    itf.valid_i <= 1'b1;
endtask

task check_equal(input val_t expected);
    @(tb_clk);
    assert (itf.val_o == expected) else begin
        itf.tb_report_dut_error(READ_ERROR);
        $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, expected);
    end
endtask

val_t expected;
val_t read_o;

initial begin
    $display("Starting CAM Tests");
    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    for (int i = 0; i < camsize_p; i++) begin
        write(i, i);
        @(tb_clk);
        expected <= i;
        read(i, read_o);
        @(tb_clk iff itf.valid_o);
        check_equal(expected);
    end

    reset();

    for (int i = 0; i < camsize_p; i++) begin
        write(i, i);
        @(tb_clk);
        //shout out to NVIDA RTX 4090
        write(i, (i ^ 16'h4090));
    end

    reset();

    for (int i = 0; i < 2 * camsize_p; i++) begin
        write(i, i);
        @(tb_clk);
        read(i, expected);
        @(tb_clk iff itf.valid_o);
        check_equal(expected);
    end

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench

