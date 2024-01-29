module execute
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    /* input signals from ID/EX buffer */
    input ID_EX_stage_t ex_in,
    input rv32i_reg ex_to_mem_rd,
    input rv32i_reg mem_to_wb_rd,
    input logic ex_to_mem_load_regfile,
    input logic mem_to_wb_load_regfile,
    input rv32i_word ex_mem_rd_data,
    input rv32i_word mem_wb_rd_data,
    input logic use_branch,  

    /* output to EX/MEM buffer */
    output logic ex_stall,
    output EX_MEM_stage_t ex_out
    // output pcmux::pcmux_sel_t pcmux_sel,
    // output logic branch_take // 0 if there's not taking branch, 1 if we are taking branch
    // input logic branch_take
);
    /* ALU signals */
    rv32i_word alumux1_out;
    rv32i_word alumux2_out;
    rv32i_word alu_out;

    /* CMP signals */
    logic br_en;
    rv32i_word cmpmux_out;
    logic is_jalr, is_jal;

    /* MAR signals */
    rv32i_word marmux_out;
    rv32i_word rvfi_pc_wdata_ex;

    /* data forwarding mux signals */
    data_forward_t forwardA_sel, forwardB_sel;
    rv32i_word forward_rs1;
    rv32i_word forward_rs2;

    logic branch_take;
    pcmux::pcmux_sel_t pcmux_sel;

    /* m extention signals */
    rv32i_word m_alu_out;
    logic m_alu_done;
    m_funct3_t m_funct3;
    logic m_alu_act;

    
    assign m_funct3 = m_funct3_t'(ex_in.ctrl_wd.funct3);
    assign m_alu_act = ex_in.ctrl_wd.ex_ctrlwd.m_extension_act;
    assign ex_stall = ~(m_alu_done);

    m_extension_alu m_alu(
        .clk(clk),
        .rst(rst),
    
        // data input and opcode (operation)
        .rs1_data_i(alumux1_out),
        .rs2_data_i(alumux2_out),
        .funct3(m_funct3),
        .m_alu_active(m_alu_act),   // used to enable mul, div, rem, 1: unit is active, do work; 0: do not do work

        // output
        .m_ex_alu_done(m_alu_done),
        .rd_data_o(m_alu_out)
);

    assign is_jalr = (ex_in.ctrl_wd.opcode == op_jalr);
    assign is_jal = (ex_in.ctrl_wd.opcode == op_jal);

    alu ALU(
        .aluop(ex_in.ctrl_wd.ex_ctrlwd.aluop),
        .a(alumux1_out),
        .b(alumux2_out),
        .f(alu_out)
    );

    cmp CMP(
        .a(forward_rs1),
        // .a(ex_in.rs1_out),
        .b(cmpmux_out),
        .cmpop(ex_in.ctrl_wd.ex_ctrlwd.cmpop),
        .br_en(br_en) 
    );
    /* This is the earliest point we know that the branch is going to be taken */

    forward_unit forward_unit(
        // input
        .ex_to_mem_rd(ex_to_mem_rd),
        .mem_to_wb_rd(mem_to_wb_rd),
        .id_to_ex_rs1(ex_in.ctrl_wd.rs1),
        .id_to_ex_rs2(ex_in.ctrl_wd.rs2),
        .ex_to_mem_load_regfile(ex_to_mem_load_regfile),
        .mem_to_wb_load_regfile(mem_to_wb_load_regfile),
        
        // output
        .forwardA_o(forwardA_sel),
        .forwardB_o(forwardB_sel)
    );

    /*********** EX Muxes **********/
    always_comb begin : F_MUX
        unique case (forwardA_sel)
            id_ex_fd: forward_rs1 = ex_in.rs1_out;
            ex_mem_fd: forward_rs1 = ex_mem_rd_data;
            mem_wb_fd: forward_rs1 = mem_wb_rd_data;
            default: forward_rs1 = ex_in.rs1_out;
        endcase

        unique case (forwardB_sel)
            id_ex_fd: forward_rs2 = ex_in.rs2_out;
            ex_mem_fd: forward_rs2 = ex_mem_rd_data;
            mem_wb_fd: forward_rs2 = mem_wb_rd_data;
            default: forward_rs2 = ex_in.rs2_out;
        endcase
    end : F_MUX
    always_comb begin : EX_MUXES

        rvfi_pc_wdata_ex = ex_in.rvfi_d.rvfi_pc_wdata;
        branch_take = 1'b0;

        unique case (ex_in.ctrl_wd.ex_ctrlwd.alumux1_sel)
            alumux::rs1_out: alumux1_out = forward_rs1;     // seem like this
            alumux::pc_out: alumux1_out = ex_in.ctrl_wd.pc;
        endcase

        unique case (ex_in.ctrl_wd.ex_ctrlwd.alumux2_sel)
            alumux::i_imm: alumux2_out = ex_in.i_imm;
            alumux::u_imm: alumux2_out = ex_in.u_imm;
            alumux::b_imm: alumux2_out = ex_in.b_imm;
            alumux::s_imm: alumux2_out = ex_in.s_imm;
            alumux::j_imm: alumux2_out = ex_in.j_imm;
            alumux::rs2_out: alumux2_out = forward_rs2;
            default: alumux2_out = ex_in.i_imm;
        endcase

        unique case (ex_in.ctrl_wd.ex_ctrlwd.cmpmux_sel)
            cmpmux::rs2_out: cmpmux_out = forward_rs2; // ex_in.rs2_out;    // seem like this
            cmpmux::i_imm: cmpmux_out = ex_in.i_imm;
        endcase

        unique case (is_jalr)
            1'b0: 
            begin
                unique case(is_jal)
                    1'b0: begin
                        pcmux_sel = pcmux::pcmux_sel_t'({1'b0, br_en & ex_in.ctrl_wd.ex_ctrlwd.is_branch}); 
                        if(br_en & ex_in.ctrl_wd.ex_ctrlwd.is_branch) begin // if there is a branch
                            rvfi_pc_wdata_ex = alu_out;
                            branch_take = 1'b1;
                        end
                    end
                    1'b1: begin
                        pcmux_sel = pcmux::alu_out;
                        rvfi_pc_wdata_ex = alu_out;
                        branch_take = 1'b1;
                    end
                endcase
            end
            1'b1:
            begin
                pcmux_sel = pcmux::alu_mod2;
                rvfi_pc_wdata_ex = {alu_out[31:1], 1'b0};
                branch_take = 1'b1;
            end
            default: begin 
                pcmux_sel = {1'b0, br_en & ex_in.ctrl_wd.ex_ctrlwd.is_branch};
                if(br_en & ex_in.ctrl_wd.ex_ctrlwd.is_branch) begin
                    rvfi_pc_wdata_ex = alu_out;
                    branch_take = 1'b1;
                end
            end 
        endcase

        unique case (ex_in.ctrl_wd.ex_ctrlwd.marmux_sel)
            marmux::pc_out: marmux_out = ex_in.ctrl_wd.pc;
            marmux::alu_out: marmux_out = alu_out;
        endcase


    end : EX_MUXES


/* 
 * signal are now pass to the next stage
 * always_comb has repect the order of the signal
 * that's why we leave it to the end
 */
    always_comb begin
        ex_out.cmp_out = br_en;
        ex_out.ctrl_wd = ex_in.ctrl_wd;
        ex_out.alu_out = alu_out;
        if(m_alu_act) begin
            ex_out.alu_out = m_alu_out;
        end
        ex_out.mar = marmux_out;
        ex_out.mem_data_out = forward_rs2 << (8 * marmux_out[1:0]); 
        ex_out.u_imm = ex_in.u_imm;
        ex_out.rd = ex_in.rd;

        ex_out.pcmux_sel = pcmux_sel;
        ex_out.branch_take = branch_take;
        
        ex_out.rvfi_d = ex_in.rvfi_d;
        ex_out.rvfi_d.rvfi_pc_wdata = rvfi_pc_wdata_ex; // something wrong here, causing pc_wdata to be wrong
        // if(forwardA_sel != id_ex_fd) begin

        ex_out.rvfi_d.rvfi_rs1_rdata = forward_rs1;
        // end
        // if(forwardB_sel != id_ex_fd) begin
        ex_out.rvfi_d.rvfi_rs2_rdata = forward_rs2;
        // end
        if(use_branch) begin
            ex_out = '0;
        end
    end

endmodule