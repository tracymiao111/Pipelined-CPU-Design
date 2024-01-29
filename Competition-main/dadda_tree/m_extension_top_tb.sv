module dadda_tree_dut_tb
import m_extension::*;
();

    timeunit 1ns;
    timeprecision 1ns;

    bit clk;
    initial clk = 1'b1;
    always #1 clk = ~clk;

    bit rst;
    task reset_all();
        rst = 1'b1;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
    endtask
    //----------------------------------------------------------------------
    // Waveforms.
    //----------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end
    
    // random class
    class RandData;
        rand bit [31:0] data;
    endclass
    
    // input and output for dut
    logic [31:0] operandA;
    logic [31:0] operandB;
    logic [31:0] productAB;
    m_extension::m_funct3 funct3;
    logic mul_done;
    logic mul_on;

    // input and output for solution
    logic [31:0] correct_A;
    logic [31:0] correct_B;
    logic [63:0] correct_ans;
    logic [31:0] corrent_remainder;

    // // dut initialization
    // dadda_tree dut(
    //     .opA(operandA),
    //     .opB(operandB),
    //     .prodAB(productAB) 
    // );
    multiplier dut(
        .clk(clk),
        .rst(rst),
        .rs1_data(operandA),
        .rs2_data(operandB),
        .funct3(funct3),
        .is_mul(mul_on),
        .mul_done(mul_done),
        .mul_out(productAB)
    );
    
    logic start, div_done;
    logic [31:0] dividend, divisor, quotient, remainder;
    divider dut2(
        .clk(clk),
        .rst(rst),
        .dividend(dividend),   
        .divisor(divisor),     /*** dividend / divisor ***/
        .funct3(funct3),
        .start(start),
        .div_done(div_done),      
        .quotient(quotient),
        .remainder(remainder)
    );



    logic [31:0] rd_data_o;
    logic m_extension_alu_act;
    logic m_ex_alu_done;
    m_extension_alu dut_fin(
        .clk(clk),
        .rst(rst),
        
        // data input and opcode (operation)
        .rs1_data_i(operandA),
        .rs2_data_i(operandB),
        .funct3(funct3),
        .m_alu_active(m_extension_alu_act),   // used to enable mul, div, rem, 1: unit is active, do work; 0: do not do work
        // results
        .m_ex_alu_done(m_ex_alu_done),
        .rd_data_o(rd_data_o)
    );
    // srt_divider srt_dut2(
    //     .clk(clk),
    //     .rst(rst),
    //     .dividend(dividend),   
    //     .divisor(divisor),     /*** dividend / divisor ***/
    //     // .complete(div_done),      
    //     .quotient(quotient),
    //     .remainder(remainder)
    // );

    RandData rand_A = new;
    RandData rand_B = new;

    int testing_threshold;
    int error_count;
    
    // dadda tree unsigned multiplication
    task unsigned_dadda_tree();
        // testing loop
        for(int i = 0; i < testing_threshold; ++i) begin
            rand_A.randomize();
            rand_B.randomize();

            // correct ans
            correct_A = rand_A.data;
            correct_B = rand_B.data;
            correct_ans = correct_A * correct_B;

            operandA <= rand_A.data;
            operandB <= rand_B.data;

            @(posedge clk iff mul_done == 1'b1);
            // @(posedge clk);

            if(dut.mul_result !== correct_ans) begin
                $display("A: 0x%0h", operandA);
                $display("B: 0x%0h", operandB);
                $display("dadda:   0x%0h", dut.mul_result);
                $display("correct: 0x%0h\n", correct_ans);
                error_count += 1;
            end
        end
    endtask

    // logic [31:0] tempA;
    // logic [31:0] tempB;
    task signed_dadda_tree(logic A_const, logic B_const);
        $write("%c[0;31m", 27);
        for(int i = 0; i < testing_threshold; ++i) begin
            rand_A.randomize() with { data[31] == A_const; };
            rand_B.randomize() with { data[31] == B_const; };

            correct_A = rand_A.data;
            correct_B = rand_B.data;
            correct_ans = $signed(correct_A) * $signed(correct_B);

            operandA <= rand_A.data;
            operandB <= rand_B.data;

            // repeat (4) @(posedge clk);
            @(posedge clk iff mul_done == 1'b1);
            
            if(correct_ans !== dut.mul_result) begin
                error_count += 1;
                $display("correct_A: 0x%0h", $signed(correct_A));
                $display("correct_B: 0x%0h", $signed(correct_B));
                $display("correct_ans: %0d", correct_ans);
                $display("correct_ans: %0d", $signed(correct_ans));
                $display("dadda_tree: %0d", dut.mul_result);
                $display("dadda_tree: %0d", $signed(dut.mul_result));
            end 
        end
        $write("%c[0m", 27);
    endtask
    
    logic [63:0] temp;
    task mul_opcode_test(m_extension::m_funct3 op);
        funct3 = op; // setting the funct3 signal
        for(int i = 0; i < testing_threshold; ++i) begin
            // rand_A.randomize();
            // rand_B.randomize();
            rand_A.randomize() with { data[31] == 1'b1;};
            rand_B.randomize() with { data[31] == 1'b0;};
            
            correct_A = rand_A.data;
            correct_B = rand_B.data;
            correct_ans = correct_A * correct_B;

            operandA <= rand_A.data;
            operandB <= rand_B.data;
            @(posedge clk iff mul_done == 1'b1);

            if(op == mul) begin
                if(correct_ans[31:0] !== productAB) begin
                    $display("mul not working");
                    $display("correct ans whole: %0h, %0h", correct_ans[63:32], correct_ans[31:0]);
                    $display("correct ans lower 32: %0h", (correct_ans[31:0]));
                    $display("dadda: %0h", (productAB));
                end 
            end 
            if(op == mulh) begin
                correct_ans = $signed(correct_A) * $signed(correct_B);
                if(correct_ans[63:32] !== productAB) begin
                    $display("mulh not working");
                    $display("correct ans whole: %0h, %0h", correct_ans[63:32], correct_ans[31:0]);
                    $display("correct ans upper 32: %0h", (correct_ans[63:32]));
                    $display("dadda: %0h", (productAB));
                end
            end 
            if(op == mulhsu) begin
                correct_ans = $signed(correct_A) * $unsigned(correct_B);
                // $display("A: %0h", $signed(correct_A));
                // $display("B: %0h", $unsigned(correct_B));
                if(correct_ans[63:32] !== productAB) begin
                    $display("mulhsu not working");
                    $display("correct ans whole: %0h, %0h", correct_ans[63:32], correct_ans[31:0]);
                    $display("correct ans upper 32: %0h", (correct_ans[63:32]));
                    $display("dadda: %0h", (productAB));
                    $display("dadda whole: %0h, %0h", dut.mul_result[63:32], dut.mul_result[31:0]);
                    temp = dut.row_top + dut.row_bot;
                    $display("dadda whole no negate: %0h, %0h", temp[63:32], temp[31:0]);

                end
            end
            if(op == mulhu) begin
                correct_ans = $unsigned(correct_A) * $unsigned(correct_B);
                if(correct_ans[63:32] !== productAB) begin
                    $display("mulh not working");
                    $display("correct ans whole: %0h, %0h", correct_ans[63:32], correct_ans[31:0]);
                    $display("correct ans upper 32: %0h", (correct_ans[63:32]));
                    $display("dadda: %0h", (productAB));
                end
            end
        end
    endtask 


    task simple_unsigned_div();
        start = 1'b1;
        $write("%c[0m",27);
        for(int i = 0; i < testing_threshold; i++) begin
            rand_A.randomize();
            rand_B.randomize();
            dividend = rand_A.data;
            divisor  = rand_B.data;
            correct_ans = rand_A.data / rand_B.data;
            corrent_remainder = rand_A.data % rand_B.data;
            @(posedge clk iff div_done == 1'b1);

            if(quotient !== correct_ans[31:0] || remainder !== corrent_remainder) begin
                $display("dividend: 0x%0h", rand_A.data);
                $display("divisor: 0x%0h", rand_B.data);
                if(quotient !== correct_ans[31:0]) begin
                    $display("Divider quotient: 0x%0h", quotient);
                    $display("Correct quotient: 0x%0h", correct_ans);
                end

                if(remainder !== corrent_remainder) begin
                    $display("Divider remainder: 0x%0h", remainder);
                    $display("Correct remainder: 0x%0h", corrent_remainder);
                end
                error_count += 1;
                $display();
            end
        end
    endtask
    

    task mulsu_behavior_testing(logic [31:0] signed_n, logic [31:0] unsigned_n);
        funct3 = mulhsu;
        mul_on = 1'b1;
        operandA = signed_n;
        operandB = unsigned_n;
        @(posedge clk iff mul_done == 1'b1);
        // if(productAB !== 32'hFFFFFFFF) begin
        $display("top: 0x%0h, 0x%0h", dut.row_top[63:32], dut.row_top[31:0]);
        $display("bot: 0x%0h, 0x%0h", dut.row_bot[63:32], dut.row_bot[31:0]);
        $display("top + bot upper: 0x%0h", (dut.row_top[63:32] + dut.row_bot[63:32]));
        $display("raw product: %0x0h", dut.mul_result);
        $display("mulhsu op: 0x%0h", productAB);
    endtask

    task signed_div_rem_simple_test(logic [31:0] rs1, logic [31:0] rs2, m_funct3 op); 
        start = 1'b1;
        $write("%c[0m",27);
        funct3 = op;
        dividend = rs1;
        divisor = rs2;
        @(posedge clk iff div_done == 1'b1);
        $display();
        $display("rs1: 0x%0h", rs1);
        $display("rs2: 0x%0h", rs2);
        $display("rs1 / rs2 result: 0x%0h", quotient);
        $display("rs1 mod rs2 result: 0x%0h", remainder);
    endtask

    task mult_op_selection(logic [31:0] rs1, logic [31:0] rs2, m_funct3 op);
        operandA = rs1;
        operandB = rs2;
        funct3 = op;
        @(posedge clk iff mul_done == 1'b1);
        $display();
        $display("rs1: 0x%0h", rs1);
        $display("rs2: 0x%0h", rs2);
        $display("rs1 * rs2 result: 0x%0h", productAB);
    endtask

    initial begin
        $display("%c[0;36m", 27);
        $display("Dadda Tree Test Begin");
        reset_all();

        // reset the inputs of the dadda tree
        testing_threshold = 2 ** 10;
        error_count = 0;
        operandA = '0;
        operandB = '0;
        funct3 = mul;
        mul_on = '0;
        start = '0;
        m_extension_alu_act = '0;
        @(posedge clk);

        // ********** code start here **********

        /********* multiplier unit testing ************/
        // $write("%c[0;31m",27);    // color red
        // mul_on = 1'b1;

        // $display("%c[0mSimple unsigned test begin", 27);
        // $write("%c[0;31m", 27);
        // unsigned_dadda_tree();
        // $display("%c[0mSimple unsigned test end\n", 27);

        // funct3 = mulh;
        // $display("unsigned x unsigned begin");
        // signed_dadda_tree(0,0);
        // $display("unsigned x unsigned end\n");

        // $display("signed x unsigned begin");
        // signed_dadda_tree(1,0);
        // $display("signed x unsigned end\n");

        // $display("unsigned x signed begin");
        // signed_dadda_tree(0,1);
        // $display("unsigned x signed end\n");

        // $display("signed x signed begin");
        // signed_dadda_tree(1,1);
        // $display("signed x signed end");

        // mul_opcode_test(mul);
        // mul_opcode_test(mulh);
        // mul_opcode_test(mulhsu);
        // mul_opcode_test(mulhu);

        // strange operation
        // correct_ans = $signed(-1)*$unsigned(-1);
        // $display("%0h", correct_ans);
        // $display("%0h %0h", correct_ans[63:32], correct_ans[31:0]);
        /********* multiplier unit testing ************/


        /********* divider unit testing ************/
        // remainder = $signed(4) % $signed(-6);
        // $display("remainder is: %0d, 0x%0h", remainder, remainder);
        // funct3 = divu;
        
        // simple_unsigned_div();
        // mulsu_behavior_testing(32'h2, 32'h2);
        signed_div_rem_simple_test(-32'h2, 32'h3, div);
        /********* divider unit testing ************/

        /********* full m extension unit testing ************/
        
        // m_extension not in use test start
        // @(posedge clk iff m_ex_alu_done);
        // @(posedge clk);
        // // m_extension not in use test end

        // // activate test begin
        // m_extension_alu_act = 1'b1;
        // $display(m_ex_alu_done);
        // @(posedge clk);
        // $display(m_ex_alu_done);
        // @(posedge clk iff m_ex_alu_done);
        // activate test end 

        /********* full m extension unit testing ************/

        
        // color display for pass and failed
        if(error_count === 0) begin
            $display("%c[1;32m",27);
            $display("Pass");
        end
        else begin
            $display("%c[1;31m",27); 
            $display("Error Count: %0d", error_count);
            $display("Fail");
        end 
        // ********** code end here **********
        
        $display("%c[0;36m", 27);
        $display("Dadda Tree Test End\n");
        $write("%c[0m",27);
        $finish;
    end 

endmodule



// start = 1'b1;
// rand_A.randomize();
// rand_B.randomize();
// dividend = rand_A.data;
// divisor  = rand_B.data;
// correct_ans = rand_A.data / rand_B.data;
// corrent_remainder = rand_A.data % rand_B.data;
// @(posedge clk);
// @(posedge clk iff dut2.remainder_reg == 32'b0);
// if(quotient !== correct_ans[31:0] || remainder !== corrent_remainder) begin
//     $display("dividend: 0x%0h", rand_A.data);
//     $display("divisor: 0x%0h", rand_B.data);
//     $display("Divider quotient: 0x%0h", quotient);
//     $display("Correct quotient: 0x%0h", correct_ans);
//     $display("Divider remainder: 0x%0h", remainder);
//     $display("Correct remainder: 0x%0h", corrent_remainder);
// end