module icache_bk_datapath 
import rv32i_types::*;
#(
    parameter       s_offset = 5,
    parameter       s_index  = 3,
    parameter       s_tag    = 32 - s_offset - s_index,
    parameter       s_mask   = 2**s_offset,
    parameter       s_line   = 8*s_mask
)
( 
    input   logic           clk,
    input   logic           rst,

    /* signals from CPU */
    input   logic [31:0]    mem_address,
    // input logic [31:0] mem_byte_enable256,
    output  logic [s_line-1:0]     mem_rdata256,
    
    /* signals for main memory */
    input   logic [s_line-1:0]     pmem_rdata,
    output  logic [31:0]    pmem_address,

    // to control
    output  logic           is_hit,

    // from control
    input   logic           load_data,
    input   logic           load_tag,
    input   logic           load_valid,
    input   logic           valid_in
);

    /* local variables */
    logic [s_line-1:0] data_arr_in, data_arr_out;
    logic [s_tag-1:0] tag_arr_in, tag_arr_out;

    logic valid_out, hit;
    logic [s_index-1:0] set_idx;

    /* assignments */
    assign tag_arr_in = mem_address[31:(s_offset + s_index)];
    assign set_idx = mem_address[(s_offset + s_index -1):s_offset];
    assign mem_rdata256 = data_arr_out;
    assign data_arr_in = pmem_rdata;
    assign is_hit = hit;
    assign pmem_address = {mem_address[31:s_offset], {(s_offset){1'b0}}};


    icache_bk_data_array #(.s_offset(s_offset), .s_index(s_index)) icache_data_array (
        .clk(clk),
        .rst(rst),
        .web(load_data),
        .index(set_idx),
        .datain(data_arr_in),
        .dataout(data_arr_out)
    );

    icache_bk_array #(.datawidth(1), .s_index(s_index)) valid_bit_array(
        .clk(clk),
        .rst(rst),
        .load(load_valid),
        .index(set_idx),
        .datain(valid_in),
        .dataout(valid_out)
    );
    
    icache_bk_array #(.datawidth(s_tag), .s_index(s_index)) tag_bit_array(
        .clk(clk),
        .rst(rst),
        .load(load_tag),
        .index(set_idx),
        .datain(tag_arr_in),
        .dataout(tag_arr_out)
    );

    assign hit = (tag_arr_in == tag_arr_out) & valid_out;




endmodule 