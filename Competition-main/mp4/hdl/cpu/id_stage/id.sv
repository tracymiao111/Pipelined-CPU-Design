
module i_decode 
import rv32i_types::*;
(
    /* inputs */
    input logic             clk,
    input logic             rst,
    input IF_ID_stage_t     id_in,
    input rv32i_word        regfile_in,
    input logic             load_regfile,
    input rv32i_reg         rd,
    input logic             branch_take,
    input logic             valid_forward,
    /* outputs to ID/EX buffer*/
    output ID_EX_stage_t    id_out
);
    /* RegFile signals */
    ctrl_word_t control_word;
    rv32i_reg rs1, rs2, dest_reg;
    /* control word signals */
    assign rs1 = id_out.ctrl_wd.rs1;
    assign rs2 = id_out.ctrl_wd.rs2;

    /* signals to send out to next stage */
    assign id_out.i_imm = {{21{id_in.ir.word[31]}}, id_in.ir.word[30:20]};
    assign id_out.s_imm = {{21{id_in.ir.word[31]}}, id_in.ir.word[30:25], id_in.ir.word[11:7]};
    assign id_out.b_imm = {{20{id_in.ir.word[31]}}, id_in.ir.word[7], id_in.ir.word[30:25], id_in.ir.word[11:8], 1'b0};
    assign id_out.u_imm = {id_in.ir.word[31:12], 12'h000};
    assign id_out.j_imm = {{12{id_in.ir.word[31]}}, id_in.ir.word[19:12], id_in.ir.word[20], id_in.ir.word[30:21], 1'b0};
    assign id_out.rd = dest_reg;

    /* control word */
    control_word ControlWord (
        .pc_i(id_in.pc),
        .instr_i(id_in.ir.word),
        .dest_r(dest_reg),
        // .src_1(rs1),
        // .src_2(rs2),
        .control_words_o(control_word)
    );

    /* regfile */
    regfile RegFile(
        .clk(clk),
        .rst(rst),
        .load(load_regfile),
        .in(regfile_in),  
        .valid_forward(valid_forward),
        .src_a(rs1),
        .src_b(rs2),
        .dest(rd), // passed from write_back
        .reg_a(id_out.rs1_out),
        .reg_b(id_out.rs2_out)
    );
    
    /* possible Hazard Detection Unit in forwarding */
    /* save for cp2 */


    /* setting up rvfi signals */
    always_comb begin
        id_out.rvfi_d = id_in.rvfi_d;
        id_out.ctrl_wd = control_word;
        /* some other signals that I need to turn on */
        id_out.rvfi_d.rvfi_inst = id_in.ir.word;
        id_out.rvfi_d.rvfi_rs1_addr = rs1;
        id_out.rvfi_d.rvfi_rs2_addr = rs2;
        id_out.rvfi_d.rvfi_rs1_rdata = id_out.rs1_out;
        id_out.rvfi_d.rvfi_rs2_rdata = id_out.rs2_out;
        id_out.rvfi_d.rvfi_rd_addr = dest_reg;

        if(branch_take) begin
            id_out.ctrl_wd = '0;
            // TODO: RVFI might complaint
        end
    end 


endmodule 
