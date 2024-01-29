module bus_adapter
#(
    parameter cacheline_size = 256,
    parameter byte_enable_size = cacheline_size / 8,     // right shift 3 = divided by 8
    parameter extend_size = cacheline_size / 32,          // right shift 5 = divided by 32
    parameter addr_bit_sel = ($clog2(extend_size) - 1)      // if it is 128, then 128 / 32 is 4, log(4)=2, size 2, so [2+2-1:2] = [3:2] gives 4 options
)    
(
    input   logic   [31:0]  address,
    output  logic   [cacheline_size - 1:0] mem_wdata256,
    input   logic   [cacheline_size - 1:0] mem_rdata256,
    input   logic   [31:0]  mem_wdata,
    output  logic   [31:0]  mem_rdata,
    input   logic   [3:0]   mem_byte_enable,
    output  logic   [byte_enable_size - 1:0]  mem_byte_enable256
);

assign mem_wdata256 = {(extend_size){mem_wdata}};
assign mem_rdata = mem_rdata256[(32*address[ (2 + addr_bit_sel) :2]) +: 32]; // [4:2] = 3 bits, 8 of them, reduce to 2 bits cuz 128 can only 4
assign mem_byte_enable256 = { {(byte_enable_size-4){1'b0}} , mem_byte_enable} << (address[(2 + addr_bit_sel):2]*4);

endmodule : bus_adapter
