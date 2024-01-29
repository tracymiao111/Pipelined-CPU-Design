module l2_cache #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)(
    input                   clk,
    input                   rst,

    /* Arbiter side signals */
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    output  logic   [s_line-1:0] mem_rdata,
    input   logic   [s_line-1:0] mem_wdata,
    input   logic   [s_mask-1:0] mem_byte_enable256,
    output  logic           mem_resp,

    /* Cacheline Adaptor side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [s_line-1:0] pmem_rdata,
    output  logic   [s_line-1:0] pmem_wdata,
    input   logic           pmem_resp
);


logic [s_line-1:0] mem_rdata256, mem_wdata256;
logic load_data, load_tag, load_dirty, load_valid, load_plru;
logic valid_in, dirty_in;
logic is_hit, is_dirty;
logic is_allocate, use_replace;


assign mem_rdata = mem_rdata256;
assign mem_wdata256 = mem_wdata;

l2_cache_control l2_cache_control(
    .clk,        // clock
    .rst,      // rst
    // memory response
    .pmem_resp,
    .mem_resp,

    // memory read and write
    .mem_read,
    .mem_write,
    .pmem_read,
    .pmem_write,
    
    // input to FSM, state transition purpose
    .is_hit, 
    // input logic is_valid, 
    .is_dirty,

    // load signals
    .load_data, 
    .load_tag, 
    .load_dirty, 
    .load_valid, 
    .load_plru,

    // valid input and dirty input to the array
    .valid_in, 
    .dirty_in,
    
    // state indicator
    .is_allocate,

    // replacement in use
    .use_replace
);

l2_cache_datapath #(.s_offset(s_offset), .s_index(s_index)) 
l2_cache_datapath(
    .clk,
    .rst,

    .mem_address,
    .mem_wdata256,
    .mem_rdata256,
    .mem_byte_enable256, // this is for writing to the cacheline

    .pmem_rdata,
    .pmem_wdata,
    .pmem_address,

    // to control
    .is_hit,
    .is_dirty, // dirty_bit_output[#ways]


    // from control
    .is_allocate,
    .use_replace,    // is_neg
    .load_data,
    .load_tag,
    .load_dirty,
    .load_valid,
    .load_plru,
    .valid_in,
    .dirty_in
);

endmodule : l2_cache
