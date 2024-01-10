module cache #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)(
    input                   clk,
    input                   rst,

    /* CPU side signals */
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic   [31:0]  mem_byte_enable,
    output  logic   [255:0] mem_rdata,
    input   logic   [255:0] mem_wdata,
    output  logic           mem_resp,

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [255:0] pmem_rdata,
    output  logic   [255:0] pmem_wdata,
    input   logic           pmem_resp
);

/* state some internal singal between control & datapah */
logic hit_sig;
logic dirty_sig;
logic allo_sig;
logic rep_sig;
logic load_data;
logic load_tag;
logic load_valid;
logic load_dirty;
logic load_plru;
logic valid_i;
logic dirty_i;

logic [s_mask - 1 : 0] mem_byte_enable256;
logic [s_line - 1 : 0] mem_rdata256;
logic [s_line - 1 : 0] mem_wdata256;

assign mem_byte_enable256 = mem_byte_enable;
assign mem_rdata          = mem_rdata256;
assign mem_wdata256       = mem_wdata;

cache_control control
(.*);

cache_datapath datapath
(.*);

endmodule : cache
