module write_back 
import rv32i_types::*;
(   
    /* input signals from MEM_WB buffer */
    input MEM_WB_stage_t wb_in,
    input rv32i_word    dmem_rdata,
    /* output to regfile */
    output rv32i_word regfile_in,
    output logic load_regfile
);
    /* local variables */
    rv32i_word regfilemux_out;
    logic [7:0] mdrreg_b;
    logic [15:0] mdrreg_h;
    // logic [3:0] rmask;

    /* assignments for output signal */
    assign regfile_in = regfilemux_out;
    assign load_regfile = wb_in.ctrl_wd.wb_ctrlwd.load_regfile;

    

    /* shift bits according to the last 2 bit of mar */
    // assign mdrreg_b = wb_in.mdr[(wb_in.mar[1:0] * 8) +: 8];
    // assign mdrreg_h = wb_in.mdr[(wb_in.mar[1:0] * 8) +: 16];
    assign mdrreg_b = dmem_rdata[(wb_in.mar[1:0] * 8) +: 8];
    assign mdrreg_h = dmem_rdata[(wb_in.mar[1:0] * 8) +: 16];

    always_comb begin : MUX
        unique case (wb_in.ctrl_wd.wb_ctrlwd.regfilemux_sel)
            regfilemux::alu_out: regfilemux_out = wb_in.alu_out;
            regfilemux::br_en: regfilemux_out = {31'b0, wb_in.cmp_out[0]};
            regfilemux::u_imm: regfilemux_out = wb_in.u_imm;
            regfilemux::pc_plus4: regfilemux_out = wb_in.ctrl_wd.pc + 4;

            // regfilemux::lw: regfilemux_out = wb_in.mdr;
            regfilemux::lw: regfilemux_out = dmem_rdata;
            regfilemux::lb: regfilemux_out = {{24{mdrreg_b[7]}}, mdrreg_b};
            regfilemux::lbu: regfilemux_out = {{24{1'b0}}, mdrreg_b};
            regfilemux::lh: regfilemux_out = {{16{mdrreg_h[15]}}, mdrreg_h};
            regfilemux::lhu: regfilemux_out = {{16{1'b0}}, mdrreg_h};
            default: regfilemux_out = wb_in.alu_out;
        endcase
    end : MUX


endmodule
