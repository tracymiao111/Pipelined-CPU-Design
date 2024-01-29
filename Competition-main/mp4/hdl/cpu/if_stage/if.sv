module i_fetch
import rv32i_types::*;
(
    /* inputs */
    input clk,
    input rst,
    input rv32i_word alu_out,
    input pcmux::pcmux_sel_t pcmux_sel,
    input logic load_pc,
    input logic imem_resp, /* response from icache */
    input logic branch_take,
    input rv32i_word imem_rdata,
    // input logic dmem_stall,

    /* outputs to IF/ID buffer */
    output IF_ID_stage_t if_output,

    /* outputs to Magic Memory */
    output logic imem_read,
    output logic [31:0] imem_address
);
/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out, imemmux_out;
logic imemmux_sel;

/*****************************************************************************/
// assign imem_address = if_output.pc;
assign imem_read = 1'b1; //for CP1
assign imem_address = imemmux_out;
assign imemmux_sel = (imem_resp & load_pc) | branch_take; // TODO: cp2
// assign imemmux_sel = (imem_resp dda)
// setting up rvfi signal
always_comb begin    
    if_output.rvfi_d = '0;// to synth
  
    case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = if_output.pc + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
        default: pcmux_out = if_output.pc + 4;
    endcase
    
    // imem_addr selection
    unique case(imemmux_sel)                  // TODO: a stalling problem, 1
        1'b1: imemmux_out = pcmux_out;      
        1'b0: imemmux_out = if_output.pc;   
        default: imemmux_out = pcmux_out;
    endcase

    if_output.rvfi_d.rvfi_pc_wdata = pcmux_out;
    if_output.rvfi_d.rvfi_pc_rdata = if_output.pc;
    if_output.ir = imem_rdata;
end

pc PC (
    .clk(clk),
    .rst(rst), //may need flsuh
    .load(imemmux_sel & load_pc), //may use for stall
    .in(pcmux_out),   // sync with imem_address
    .out(if_output.pc)
);


endmodule
