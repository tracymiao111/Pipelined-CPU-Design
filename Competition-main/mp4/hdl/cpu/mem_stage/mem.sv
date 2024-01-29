module mem
import rv32i_types::*;
(   
    // input clk,
    // input rst,
    // input logic load_mdr,

    /* input signals from Magic Memory */
    input logic [31:0] dmem_rdata, 

    /* input signals from EX/MEM buffer */
    input EX_MEM_stage_t mem_in,
    // input EX_MEM_stage_t mem_in_next,
    input logic dmem_resp,

    output rv32i_word ex_to_mem_rd_data,
    /* output to EX/MEM buffer */
    output MEM_WB_stage_t mem_out,

    /* output to Magic Memory */
    output logic [31:0] dmem_wdata,
    output logic [31:0] dmem_address,
    output logic dmem_read,
    output logic dmem_write,
    output logic [3:0] mem_byte_enable
);

//to do: wmask & mem_byte_enable
//to do: figure out when to output dmem_read and dmem_write
//not declare load_mdr in version 10.20 9:13
//done: pass control_wd store_funct3 into stage
// MEM_WB_stage_t mem_mid_reg;
rv32i_word rd_data;
logic [7:0] mdrreg_b;
logic [15:0] mdrreg_h;
rv32i_word data_to_dmem;
logic [3:0] wmask;
logic [3:0] rmask;
logic [1:0] shift;
load_funct3_t load_funct3;
store_funct3_t store_funct3;
regfilemux::regfilemux_sel_t reg_mux_sel;


assign load_funct3 = load_funct3_t'(mem_in.ctrl_wd.funct3);
assign store_funct3 = store_funct3_t'(mem_in.ctrl_wd.funct3);
assign reg_mux_sel = mem_in.ctrl_wd.wb_ctrlwd.regfilemux_sel;        // regfile mux selection

/**********dmem_address***********/
assign dmem_address = {mem_in.mar[31:2], 2'b0};
assign dmem_wdata = mem_in.mem_data_out;
assign shift = mem_in.mar[1:0];
assign ex_to_mem_rd_data = rd_data;

assign mdrreg_b = dmem_rdata[(shift * 8) +: 8];
assign mdrreg_h = dmem_rdata[(shift * 8) +: 16];

// use by forwarding path
always_comb begin
    unique case (reg_mux_sel) // use the control word from mem_in
        regfilemux::alu_out: rd_data = mem_in.alu_out;
        regfilemux::br_en: rd_data = {31'b0, mem_in.cmp_out[0]};
        regfilemux::u_imm: rd_data = mem_in.u_imm;
        regfilemux::pc_plus4: rd_data = mem_in.ctrl_wd.pc + 4;
        regfilemux::lw: rd_data = dmem_rdata;
        regfilemux::lb: rd_data = {{24{mdrreg_b[7]}}, mdrreg_b};
        regfilemux::lbu: rd_data = {{24{1'b0}}, mdrreg_b};
        regfilemux::lh: rd_data = {{16{mdrreg_h[15]}}, mdrreg_h};
        regfilemux::lhu: rd_data = {{16{1'b0}}, mdrreg_h};
        default: rd_data = mem_in.alu_out;
    endcase
end 

/***************** wmask & rmask ******************************/
always_comb begin
    wmask = '0;
    rmask = '0;
    if(mem_in.ctrl_wd.opcode == op_store) begin
        case (store_funct3)
            sw: wmask = 4'b1111;
            sh: 
            begin
                case(shift)
                    2'b00: wmask = 4'b0011;
                    2'b01: wmask = 4'bxxxx;
                    2'b10: wmask = 4'b1100;
                    2'b11: wmask = 4'bxxxx;
                endcase
            end
            sb:
            begin
                case(shift)
                    2'b00: wmask = 4'b0001;
                    2'b01: wmask = 4'b0010;
                    2'b10: wmask = 4'b0100;
                    2'b11: wmask = 4'b1000;
                endcase
            end 
        endcase
    end
    else if(mem_in.ctrl_wd.opcode == op_load) begin
        case (load_funct3)
            lw: rmask = 4'b1111;
            lh, lhu: 
            begin
                case(shift)
                    2'b00: rmask = 4'b0011;
                    2'b01: rmask = 4'bxxxx;
                    2'b10: rmask = 4'b1100;
                    2'b11: rmask = 4'bxxxx;
                endcase
            end
            lb, lbu:
            begin
                case(shift)
                    2'b00: rmask = 4'b0001;
                    2'b01: rmask = 4'b0010;
                    2'b10: rmask = 4'b0100;
                    2'b11: rmask = 4'b1000;
                endcase
            end
        endcase
    end
end

/********** mem_byte_enable & dmem_read & dmem_write **************/
assign mem_byte_enable = wmask;
assign dmem_write = mem_in.ctrl_wd.mem_ctrlwd.mem_write;
assign dmem_read = mem_in.ctrl_wd.mem_ctrlwd.mem_read;

// used by pass at this checkpoint
/*****transfer to next stage******/
// always_comb begin
//     mem_out.mar = mem_mid_reg.mar;
//     mem_out.mdr = mem_mid_reg.mdr;   // mdr next value
//     if(dmem_resp) mem_out.mdr = dmem_rdata;   // mdr next value    
//     if(dmem_resp) mem_out.rvfi_d.rvfi_mem_rdata   = dmem_rdata;
//     if(dmem_write) mem_out.rvfi_d.rvfi_mem_wdata   = dmem_wdata; 
// end

/* TODO: we need to use dmem_resp for cp2. Now we just skip dmem_resp for w/r dmem. 
 *  SRAM is skipping MEM_to_WB, we should change it to skipping EX_to_MEM.
*/

// use for later
always_comb begin : transfer_to_next
    mem_out.ctrl_wd = mem_in.ctrl_wd;
    mem_out.cmp_out = mem_in.cmp_out;
    mem_out.u_imm = mem_in.u_imm;
    mem_out.rd = mem_in.rd;
    mem_out.alu_out = mem_in.alu_out;
    mem_out.mar = mem_in.mar;
    mem_out.mdr = dmem_rdata;   // mdr next value TODO: need to fix in CP2 
    // if(dmem_resp) mem_out.mdr = dmem_rdata;   // mdr next value, for later part
    
    // rvfi section
    mem_out.rvfi_d                  = mem_in.rvfi_d;
    mem_out.rvfi_d.rvfi_mem_addr    = {mem_in.mar[31:2], 2'b0};
    mem_out.rvfi_d.rvfi_mem_rmask   = rmask; 
    mem_out.rvfi_d.rvfi_mem_wmask   = wmask;
    mem_out.rvfi_d.rvfi_mem_rdata = '0; // TODO: need to fix later: CP2
    if(dmem_resp) mem_out.rvfi_d.rvfi_mem_rdata   = dmem_rdata; // for later part
    mem_out.rvfi_d.rvfi_mem_wdata   = dmem_wdata; 

end: transfer_to_next


endmodule