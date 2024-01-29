module control_word
import rv32i_types::*;
(   
    input rv32i_word    pc_i,
    input rv32i_inst_t  instr_i,
    output rv32i_reg    dest_r,
    // output rv32i_reg    src_1,
    // output rv32i_reg    src_2,
    output ctrl_word_t  control_words_o
);

// declarations
ctrl_word_t     ctrl_word;
EX_ctrl_t       ex_ctrls;
MEM_ctrl_t      mem_ctrls;
WB_ctrl_t       wb_ctrls;
rv32i_opcode    opcode;
funct3_t        funct3;
funct7_t        funct7;

// different func3 bits
branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;
m_funct3_t m_extension_op;

// assignments
assign control_words_o = ctrl_word;

// extracting function bits
assign funct3 = instr_i.r_inst.funct3;              // instruction funct3 
assign funct7 = instr_i.r_inst.funct7;              // instruction funct7

// type casting
assign opcode = rv32i_opcode'(instr_i.word[6:0]);   // opcode lower 7 bits 
assign branch_funct3 = branch_funct3_t'(funct3);
// assign store_funct3 = store_funct3_t'(funct3); 
assign load_funct3 = load_funct3_t'(funct3);
assign arith_funct3 = arith_funct3_t'(funct3);
assign m_extension_op = m_funct3_t'(funct3);

// op_lui control words
function automatic void set_op_lui_ctrl();
    wb_ctrls.load_regfile = 1'b1;
    wb_ctrls.regfilemux_sel = regfilemux::u_imm;
endfunction

// op_auipc control words
function automatic void set_op_auipc_ctrl();
    ex_ctrls.alumux1_sel = alumux::pc_out;
    ex_ctrls.alumux2_sel = alumux::u_imm;
    ex_ctrls.aluop = alu_add;
    wb_ctrls.load_regfile = 1'b1;
    wb_ctrls.regfilemux_sel = regfilemux::alu_out;
endfunction

// op_jal control words
function automatic void set_op_jal_ctrl();
    ex_ctrls.alumux1_sel = alumux::pc_out; // use pc 
    ex_ctrls.alumux2_sel = alumux::j_imm; 
    ex_ctrls.aluop = alu_add;
    wb_ctrls.load_regfile = 1'b1;
    wb_ctrls.regfilemux_sel = regfilemux::pc_plus4;
    ex_ctrls.is_branch = 1'b1;
endfunction

// op_jalr control word
function automatic void set_op_jalr_ctrl();
    // jalr follows i-type format
    ex_ctrls.alumux1_sel = alumux::rs1_out; // use reg
    ex_ctrls.alumux2_sel = alumux::i_imm;   // i-imm
    ex_ctrls.aluop = alu_add;
    wb_ctrls.load_regfile = 1'b1;
    wb_ctrls.regfilemux_sel = regfilemux::pc_plus4;
    ex_ctrls.is_branch = 1'b1;
endfunction

// op_br control word
function automatic void set_op_br_ctrl();
    ex_ctrls.alumux1_sel = alumux::pc_out;
    ex_ctrls.alumux2_sel = alumux::b_imm;
    ex_ctrls.aluop = alu_add;
    ex_ctrls.cmpmux_sel = cmpmux::rs2_out;
    ex_ctrls.cmpop = branch_funct3;
    ex_ctrls.is_branch = 1'b1; // raise is_branch flag
endfunction

// op_store control word
function automatic void set_op_store_ctrl();
    ex_ctrls.alumux1_sel = alumux::rs1_out;
    ex_ctrls.alumux2_sel = alumux::s_imm;
    ex_ctrls.aluop = alu_add;
    ex_ctrls.marmux_sel = marmux::alu_out;
    mem_ctrls.mem_write = 1'b1;
    // mem_ctrls.funct3 = funct3;
endfunction

// op_load control word
function automatic void set_op_load_ctrl();
    ex_ctrls.alumux1_sel = alumux::rs1_out;
    ex_ctrls.alumux2_sel = alumux::i_imm;
    ex_ctrls.aluop = alu_add;
    ex_ctrls.marmux_sel = marmux::alu_out;
    mem_ctrls.mem_read = 1'b1;
    // mem_ctrls.funct3 = funct3;
    wb_ctrls.load_regfile = 1'b1;
    unique case(load_funct3)
        lw: wb_ctrls.regfilemux_sel = regfilemux::lw;
        lhu: wb_ctrls.regfilemux_sel = regfilemux::lhu;
        lh: wb_ctrls.regfilemux_sel = regfilemux::lh;
        lb: wb_ctrls.regfilemux_sel = regfilemux::lb;
        lbu: wb_ctrls.regfilemux_sel = regfilemux::lbu;
        default: wb_ctrls.regfilemux_sel = regfilemux::lw;
    endcase
endfunction

// i_type instruction, or op_imm will write to register
// and does nothing in mem stage
function automatic void set_op_imm_ctrl();
    wb_ctrls.load_regfile = 1'b1;
    unique case(arith_funct3) // arithmetic operation are encoded in funct3
        slt: begin
            ex_ctrls.cmpmux_sel = cmpmux::i_imm;
            ex_ctrls.cmpop = blt;
            wb_ctrls.regfilemux_sel = regfilemux::br_en;
        end
        sltu: begin
            ex_ctrls.cmpmux_sel = cmpmux::i_imm;
            ex_ctrls.cmpop = bltu;
            wb_ctrls.regfilemux_sel = regfilemux::br_en; 
        end
        sr: begin
            ex_ctrls.alumux1_sel = alumux::rs1_out;
            ex_ctrls.alumux2_sel = alumux::i_imm;
            ex_ctrls.aluop = alu_srl;               // funct7[5] == 0
            if(funct7[5] == 1'b1) begin             // funct7[5] == 1
                ex_ctrls.aluop = alu_sra;
            end
            wb_ctrls.regfilemux_sel = regfilemux::alu_out;
        end
        default: begin  // add, and, or, xor, sll
            ex_ctrls.alumux1_sel = alumux::rs1_out;
            ex_ctrls.alumux2_sel = alumux::i_imm;
            ex_ctrls.aluop = alu_ops'(arith_funct3);
            wb_ctrls.regfilemux_sel = regfilemux::alu_out;
        end
    endcase
endfunction

// setting reg_reg instructions control signals
// reg_reg only will only use EX and WB control words
function automatic void set_op_reg_ctrl();
    wb_ctrls.load_regfile = 1'b1; // op_reg always load regfile
    if(funct7[0]) begin
        ctrl_word.valid = 1'b1; 
        ex_ctrls.alumux1_sel = alumux::rs1_out;
        ex_ctrls.alumux2_sel = alumux::rs2_out;
        wb_ctrls.regfilemux_sel = regfilemux::alu_out;
        ex_ctrls.m_extension_act = 1'b1;
    end 
    else begin
        ctrl_word.valid = 1'b1; 
        unique case (arith_funct3)
            add: begin
                ex_ctrls.alumux1_sel = alumux::rs1_out;
                ex_ctrls.alumux2_sel = alumux::rs2_out;
                ex_ctrls.aluop = alu_add;   // default to add
                if(funct7[5] == 1'b1) begin // subtract operation check
                    ex_ctrls.aluop = alu_sub;
                end
                wb_ctrls.regfilemux_sel = regfilemux::alu_out;
            end
            sr: begin
                ex_ctrls.alumux1_sel = alumux::rs1_out;
                ex_ctrls.alumux2_sel = alumux::rs2_out;
                ex_ctrls.aluop = alu_srl;   // default to logical right shift
                if(funct7[5] == 1'b1) begin // arithmetic right shift check
                    ex_ctrls.aluop = alu_sra;
                end
            end 
            slt: begin
                ex_ctrls.cmpmux_sel = cmpmux::rs2_out;
                ex_ctrls.cmpop = blt;
                wb_ctrls.regfilemux_sel = regfilemux::br_en; 
            end
            sltu: begin
                ex_ctrls.cmpmux_sel = cmpmux::rs2_out;
                ex_ctrls.cmpop = bltu;
                wb_ctrls.regfilemux_sel = regfilemux::br_en;
            end
            default: begin // and, or, xor, sll
                ex_ctrls.alumux1_sel = alumux::rs1_out;
                ex_ctrls.alumux2_sel = alumux::rs2_out;
                ex_ctrls.aluop = alu_ops'(arith_funct3);
                wb_ctrls.regfilemux_sel = regfilemux::alu_out;
            end
        endcase
    end
endfunction

always_comb begin
    ctrl_word = '0; // clear ctrl word
    ex_ctrls = '0;
    mem_ctrls = '0;
    wb_ctrls = '0;
    dest_r = '0;
    // src_1 = '0;
    // src_2 = '0;
    
    unique case(opcode) 
        op_lui: begin
            dest_r = instr_i.u_inst.rd;
            ctrl_word.valid = 1'b1; 
            set_op_lui_ctrl();
        end
        op_auipc: begin
            dest_r = instr_i.u_inst.rd;
            ctrl_word.valid = 1'b1; 
            set_op_auipc_ctrl();
        end
        op_jal: begin
            dest_r = instr_i.j_inst.rd;
            ctrl_word.valid = 1'b1; 
            set_op_jal_ctrl();
        end
        op_jalr: begin
            dest_r = instr_i.i_inst.rd;
            // src_1 = instr_i.i_inst.rs1;
            ctrl_word.valid = 1'b1; 
            ctrl_word.rs1 = instr_i.i_inst.rs1;    // control word rs1
            set_op_jalr_ctrl();
        end
        op_br: begin
            // src_1 = instr_i.b_inst.rs1;
            // src_2 = instr_i.b_inst.rs2;
            ctrl_word.valid = 1'b1; 
            ctrl_word.rs1 = instr_i.b_inst.rs1; // control word rs1
            ctrl_word.rs2 = instr_i.b_inst.rs2; // control word rs2
            set_op_br_ctrl();
        end
        op_store: begin
            // src_1 = instr_i.s_inst.rs1;
            // src_2 = instr_i.s_inst.rs2;
            ctrl_word.valid = 1'b1; 
            ctrl_word.rs1 = instr_i.s_inst.rs1; // control word rs1
            ctrl_word.rs2 = instr_i.s_inst.rs2; // control word rs2
            set_op_store_ctrl();
        end
        op_load: begin
            // src_1 = instr_i.i_inst.rs1;
            dest_r = instr_i.i_inst.rd;
            ctrl_word.valid = 1'b1; 
            ctrl_word.rs1 = instr_i.i_inst.rs1;
            set_op_load_ctrl();
        end
        op_imm: begin
            // src_1 = instr_i.i_inst.rs1;
            dest_r = instr_i.i_inst.rd;
            ctrl_word.valid = 1'b1; 
            ctrl_word.rs1 = instr_i.i_inst.rs1;
            set_op_imm_ctrl();
        end
        op_reg: begin
            // src_1 = instr_i.r_inst.rs1;
            // src_2 = instr_i.r_inst.rs2;
            dest_r = instr_i.r_inst.rd;
            ctrl_word.rs1 = instr_i.r_inst.rs1;
            ctrl_word.rs2 = instr_i.r_inst.rs2;
            set_op_reg_ctrl();
        end
        default:;
    endcase

    ctrl_word.pc = pc_i;
    ctrl_word.opcode = opcode;
    ctrl_word.funct3 = funct3;
    ctrl_word.ex_ctrlwd = ex_ctrls;
    ctrl_word.mem_ctrlwd = mem_ctrls;
    ctrl_word.wb_ctrlwd = wb_ctrls;
end
endmodule 