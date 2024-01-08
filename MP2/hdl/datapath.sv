module datapath
import rv32i_types::*;
(
    input  logic       clk,
    input  logic       rst,

    /* signals with mem */
    input  rv32i_word mem_rdata,
    output rv32i_word mem_wdata, 
    output rv32i_word mem_address,

    /* signals from control */
    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input alu_ops aluop,
    input logic   load_pc,
    input logic   load_ir,
    input logic   load_regfile,
    input logic   load_mar,
    input logic   load_mdr,
    input logic   load_data_out,
    input branch_funct3_t cmpop,

    /* signals to control */
    output rv32i_opcode opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic br_en,
    output rv32i_reg rs1,
    output rv32i_reg [4:0] rs2,
    output logic [1:0] byte_sel
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out, pc_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
rv32i_word i_imm, s_imm, b_imm, u_imm, j_imm;
rv32i_reg rd;
rv32i_word rs1_out, rs2_out;
rv32i_word regfilemux_out;
rv32i_word alumux1_out, alumux2_out ,alu_out;
rv32i_word marmux_out;
rv32i_word cmpmux_out;
/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk(clk),
    .rst(rst),
    .load(load_ir),
    .in(mdrreg_out),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

regfile REGFILE(
    .clk(clk),
    .rst(rst),
    .load(load_regfile),
    .in(regfilemux_out),
    .src_a(rs1), 
    .src_b(rs2), 
    .dest(rd),
    .reg_a(rs1_out), 
    .reg_b(rs2_out)
);

pc PC(
    .clk_i(clk),
    .rst_i(rst),
    .load_i(load_pc),
    .pc_in(pcmux_out),
    .pc_out(pc_out) 
);

/*** Memory Data Register ***/
logic [31:0] mdr;
always_ff @( posedge clk ) begin : mdr_ff
    if (rst) begin
        mdr <= '0;
    end else if (load_mdr) begin
        mdr <= mem_rdata;
    end
end : mdr_ff
assign mdrreg_out = mdr;

/*** Memory Address Register ***/
logic [31:0] mar;
always_ff @(posedge clk) begin: mar_ff
    if (rst) begin
        mar <= '0;
    end else if (load_mar) begin
        mar <= marmux_out;
    end
end: mar_ff
assign mem_address = {mar[31:2], 2'b0}; 
assign byte_sel    = mar[1:0];

/*** Memory Data Out and store byte selection ***/
logic [31:0] mem_data_out;
always_ff @(posedge clk) begin: mdo_ff
    if (rst) begin
        mem_data_out <= '0;
    end else if (load_data_out) begin
        mem_data_out <= rs2_out;
    end
end: mdo_ff

always_comb begin
    if (opcode == op_store) begin
        unique case (funct3)
            sw     : mem_wdata = mem_data_out;
            sh     : mem_wdata = byte_sel[1]? (mem_data_out << 16):(mem_data_out);
            sb     : mem_wdata = mem_wdata << (byte_sel * 4);
            default: mem_wdata = mem_data_out;
        endcase 
    end else begin
        mem_wdata = mem_data_out;
    end

end
/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU(
    .aluop(aluop),
    .a(alumux1_out), 
    .b(alumux2_out),
    .f(alu_out)
);

cmp CMP(
    .cmpop_i(cmpop),
    .a_i(rs1_out),
    .b_i(cmpmux_out),
    .cmp_o(br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out : pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
    endcase

    unique case (regfilemux_sel)
        regfilemux::alu_out : regfilemux_out = alu_out;
        regfilemux::br_en   : regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm   : regfilemux_out = u_imm; 
        regfilemux::lw      : regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb      : regfilemux_out = {{24{mdrreg_out[(byte_sel + 1) * 8 - 1]}}, mdrreg_out[((byte_sel + 1) * 8 - 1) -: 8]};
        regfilemux::lbu     : regfilemux_out = {{24{1'b0}}, mdrreg_out[((byte_sel + 1) * 8 - 1) -: 8]};
        regfilemux::lh      : regfilemux_out = {{16{mdrreg_out[(byte_sel[1] + 1) * 16 - 1]}}, mdrreg_out[((byte_sel[1] + 1) * 16 - 1) -: 16]};
        regfilemux::lhu     : regfilemux_out = {{16{1'b0}}, mdrreg_out[((byte_sel[1] + 1) * 16 - 1) -: 16]};
    endcase

    unique case (marmux_sel)
        marmux:: pc_out : marmux_out = pc_out;
        marmux:: alu_out: marmux_out = alu_out;
    endcase

    unique case (alumux1_sel)
        alumux:: rs1_out: alumux1_out = rs1_out;
        alumux:: pc_out : alumux1_out = pc_out;
    endcase

    unique case (alumux2_sel)
        alumux:: i_imm  : alumux2_out = i_imm;
        alumux:: u_imm  : alumux2_out = u_imm;
        alumux:: b_imm  : alumux2_out = b_imm;
        alumux:: s_imm  : alumux2_out = s_imm;
        alumux:: j_imm  : alumux2_out = j_imm;
        alumux:: rs2_out: alumux2_out = rs2_out; 
    endcase

    unique case (cmpmux_sel)
        cmpmux:: rs2_out: cmpmux_out = rs2_out;
        cmpmux:: i_imm  : cmpmux_out = i_imm;
    endcase
end
/*****************************************************************************/
endmodule : datapath
