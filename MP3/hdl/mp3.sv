module mp3
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    output  logic   [31:0]  bmem_address,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [63:0]  bmem_rdata,
    output  logic   [63:0]  bmem_wdata,
    input   logic           bmem_resp
);
    logic         mem_resp;                       //cache -> cpu
    logic         mem_read, mem_write;            //cpu -> cache
    logic [31 :0] mem_rdata_bus_2_cpu;            //bus -> cpu
    logic [3  :0] mem_byte_enable_cpu_2_bus;      //bus -> cpu
    logic [31 :0] mem_address;                    //cpu -> cache; cpu -> bus
    logic [31 :0] mem_wdata_cpu_2_bus;            //cpu -> bus

    logic [255:0] mem_rdata256_cache_2_bus;       //cache -> bus
    logic [255:0] mem_wdata256_bus_2_cache;       //bus -> cache
    logic [31 :0] mem_byte_enable256_bus_2_cache; //cpu -> bus

    logic [31 :0] address_i;                      //cache -> cacheline_adaptor
    logic [255:0] line_i;                         //cache -> cacheline_adaptor
    logic [255:0] line_o;                         //cacheline_adaptor -> cache
    logic         read_i, write_i;                //cache -> cacheline_adaptor
    logic         resp_o, read_o;                 //cacheline_adaptor -> cache


    cpu cpu(
        .clk                (clk),
        .rst                (rst),
        .mem_resp           (mem_resp),
        .mem_rdata          (mem_rdata_bus_2_cpu),
        .mem_read           (mem_read),
        .mem_write          (mem_write),
        .mem_byte_enable    (mem_byte_enable_cpu_2_bus),
        .mem_address        (mem_address),
        .mem_wdata          (mem_wdata_cpu_2_bus)
    );

    bus_adapter bus_adapter(
        .address            (mem_address),
        .mem_wdata256       (mem_wdata256_bus_2_cache),
        .mem_rdata256       (mem_rdata256_cache_2_bus),
        .mem_wdata          (mem_wdata_cpu_2_bus),
        .mem_rdata          (mem_rdata_bus_2_cpu),
        .mem_byte_enable    (mem_byte_enable_cpu_2_bus),
        .mem_byte_enable256 (mem_byte_enable256_bus_2_cache)
    );

    cache cache(
        .clk                (clk),
        .rst                (rst),
        .mem_address        (mem_address),
        .mem_read           (mem_read),
        .mem_write          (mem_write),
        .mem_byte_enable    (mem_byte_enable256_bus_2_cache),
        .mem_rdata          (mem_rdata256_cache_2_bus),
        .mem_wdata          (mem_wdata256_bus_2_cache),
        .mem_resp           (mem_resp),
        .pmem_address       (address_i),
        .pmem_read          (read_i),
        .pmem_write         (write_i),
        .pmem_rdata         (line_o),
        .pmem_wdata         (line_i),
        .pmem_resp          (resp_o)
    );

    cacheline_adaptor cacheline_adaptor(
        .clk                (clk),
        .reset_n            (~rst),
        .line_i             (line_i),
        .line_o             (line_o),
        .address_i          (address_i),
        .read_i             (read_i),
        .write_i            (write_i),
        .resp_o             (resp_o),
        .burst_i            (bmem_rdata),
        .burst_o            (bmem_wdata),
        .address_o          (bmem_address),
        .read_o             (bmem_read),
        .write_o            (bmem_write),
        .resp_i             (bmem_resp)
    );

endmodule : mp3
