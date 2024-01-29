module cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    /* instruction memory signals */
    output  logic   [31:0]  imem_address,
    output  logic           imem_read, //need double check
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp, //tbd

    /* data memory signals */
    output  logic   [31:0]  dmem_address,
    output  logic           dmem_read,
    output  logic           dmem_write, 
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp //tbd
    // output  logic           branch_is_take
);

/**************************** Control Signals ********************************/
pcmux::pcmux_sel_t pcmux_sel;
alumux::alumux1_sel_t alumux1_sel;
alumux::alumux2_sel_t alumux2_sel;
regfilemux::regfilemux_sel_t regfilemux_sel;
marmux::marmux_sel_t marmux_sel;
cmpmux::cmpmux_sel_t cmpmux_sel;
/***************************** Pipeline register next input ******************************/
IF_ID_stage_t if_to_id_next;
ID_EX_stage_t id_to_ex_next;
EX_MEM_stage_t ex_to_mem_next;
MEM_WB_stage_t mem_to_wb_next;
/***************************** Pipeline register ******************************/
IF_ID_stage_t if_to_id;
ID_EX_stage_t id_to_ex;
EX_MEM_stage_t ex_to_mem;
MEM_WB_stage_t mem_to_wb;
/****************************** Load Signals ********************************/
logic load_pc;
// logic load_mdr; 
logic load_regfile;
rv32i_word regfile_in;
rv32i_word ex_to_mem_rd_data;

logic ex_to_mem_load_regfile;
logic mem_to_wb_load_regfile;
/****************************** Signals for stage registers ********************************/
logic load_if_id;
logic load_id_ex;
logic load_ex_mem;
logic load_mem_wb;
logic dmem_stall;
logic imem_stall;
logic ex_stall;
/****************************** Branch Signals ********************************/
logic branch_miss;

// assign branch_is_take = branch_miss;
assign ex_to_mem_load_regfile = ex_to_mem.ctrl_wd.wb_ctrlwd.load_regfile;
assign mem_to_wb_load_regfile = mem_to_wb.ctrl_wd.wb_ctrlwd.load_regfile;

// intermediate register, use to sync with dmem, use in mem stage
// MEM_WB_stage_t mem_mid_reg;

// assign load_pc = 1'b1; //For CP1
// assign load_mdr = 1'b1; // For CP1
/******************************* IF stage ************************************/
i_fetch i_fetch(
    /* inputs */
    .clk(clk),
    .rst(rst),
    .alu_out(ex_to_mem.alu_out),
    .pcmux_sel(ex_to_mem.pcmux_sel),
    .load_pc(load_pc),//hardcode to 1 for CP1

    /* outputs to IF/ID buffer */
    .if_output(if_to_id_next),
    // .branch_take(branch_miss),
    .branch_take(ex_to_mem.branch_take),
    // .dmem_stall(dmem_stall),


    /* outputs to Magic Memory */
    .imem_rdata(imem_rdata),
    .imem_resp(imem_resp),
    .imem_address(imem_address),
    .imem_read(imem_read) //hardcode to 1 for CP1
    // .imem_resp(imem_resp)//tbd, from control_wd
);

/******************************* ID stage ************************************/
i_decode i_decode(
    /* inputs */
    .clk(clk),
    .rst(rst),
    .id_in(if_to_id),
    .regfile_in(regfile_in),
    .rd(mem_to_wb.rd),
    .load_regfile(load_regfile),
    .branch_take(ex_to_mem.branch_take),
    .valid_forward(mem_to_wb.ctrl_wd.valid),
    //.regfilemux_sel(mem_to_wb.ctrl_wd.wb_ctrlwd.regfilemux_sel), 

    /* outputs to ID/EX buffer*/
    .id_out(id_to_ex_next)
);

/******************************* EXE stage ***********************************/
execute execute(
    .clk(clk),
    .rst(rst),
    /* input signals from ID/EX buffer */
    .ex_in(id_to_ex),
    
    .ex_to_mem_rd(ex_to_mem.rd),
    .mem_to_wb_rd(mem_to_wb.rd),
    .ex_to_mem_load_regfile(ex_to_mem_load_regfile),
    .mem_to_wb_load_regfile(mem_to_wb_load_regfile),
    .ex_mem_rd_data(ex_to_mem_rd_data), 
    .mem_wb_rd_data(regfile_in),
    .use_branch(ex_to_mem.branch_take),

    /* output to EX/MEM buffer */
    .ex_stall(ex_stall),
    .ex_out(ex_to_mem_next)
    // .pcmux_sel(pcmux_sel),
    // .branch_take(branch_miss)
);

/******************************* MEM stage ***********************************/
mem mem(
    // .clk(clk),
    // .rst(rst),
    // .load_mdr(load_mdr),        //todo: also hardcode?
    /* input signals from Magic Memory */
    .dmem_rdata(dmem_rdata), 

    /* input signals from EX/MEM buffer */
    .mem_in(ex_to_mem),
    // .mem_in_next(ex_to_mem_next),

    /* output to EX/MEM buffer */
    .mem_out(mem_to_wb_next),
    .dmem_resp(dmem_resp),
    .ex_to_mem_rd_data(ex_to_mem_rd_data),


    /* output to Magic Memory */
    .dmem_wdata(dmem_wdata),
    .dmem_address(dmem_address),
    .dmem_write(dmem_write), 
    .dmem_read(dmem_read),
    .mem_byte_enable(dmem_wmask)
    // .dmem_resp(dmem_resp)//tbd, pass from control_wd
);

/******************************* WB stage ***********************************/
write_back write_back(
    .wb_in(mem_to_wb),
    .dmem_rdata(mem_to_wb.mdr),   
    /* output to regfile */
    .regfile_in(regfile_in),
    .load_regfile(load_regfile)
);


always_comb begin
    imem_stall = ~imem_resp;
    dmem_stall = (ex_to_mem.ctrl_wd.mem_ctrlwd.mem_read | ex_to_mem.ctrl_wd.mem_ctrlwd.mem_write) & (~dmem_resp);
    load_pc = 1'b1;
    load_mem_wb = 1'b1;
    if(rst) begin
        load_pc = 1'b0;
    end 
    else if (dmem_stall | ex_stall) load_pc = 1'b0;

    load_if_id = ~(dmem_stall | imem_stall | ex_stall);
    load_id_ex = ~(dmem_stall | imem_stall | ex_stall);
    load_ex_mem = ~(dmem_stall | imem_stall | ex_stall);

end
//it seems that we do not have if_id anymore?
always_ff @(posedge clk) begin
    if(rst) begin
        if_to_id <= '0;
        id_to_ex <= '0;
        ex_to_mem <= '0;
        mem_to_wb <= '0;
    end
    else begin
        // if(dmem_resp == 1'b0) begin // stalling, for latter part
        // end 
        if(load_if_id) begin
            if(ex_to_mem.branch_take || ~imem_resp) begin
                if_to_id <= '0;
            end
            else if(imem_resp) begin
                if_to_id <= if_to_id_next;
            end
        end

        // id_ex pipeline reg
        // if(load_id_ex & imem_resp) id_to_ex <= id_to_ex_next;

        if(load_id_ex) id_to_ex <= id_to_ex_next;

        // ex_mem pipeline reg
        if(load_ex_mem) ex_to_mem <= ex_to_mem_next;

        // mem_wb pipline reg
        if(load_mem_wb) begin
            if(dmem_stall | imem_stall | ex_stall) mem_to_wb.ctrl_wd.valid <= 1'b0;
            else mem_to_wb <= mem_to_wb_next;
        end

    end
end
endmodule 