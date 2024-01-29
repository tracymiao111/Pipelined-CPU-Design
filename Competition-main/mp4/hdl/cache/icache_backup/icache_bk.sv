module icache_bk 
#(
    parameter       s_offset = 5,
    parameter       s_index = 3,
    parameter       s_tag = 32 - s_offset - s_index,
    parameter       s_mask   = 2**s_offset,
    parameter       s_line   = 8*s_mask,
    parameter       num_set  = 2 ** s_index,
    parameter       addr_sel = s_offset - 1
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input logic mem_read,
    input logic [31:0] mem_address,
    output logic mem_resp,
    output logic [31:0] mem_rdata_cpu,
    // input logic branch_is_take,
    
    /* Physical memory signals */
    input logic pmem_resp,
    input logic [s_line-1:0] pmem_rdata,
    output logic [31:0] pmem_address,
    output logic pmem_read
);


logic load;
logic valid_in;
logic is_hit;
logic load_data;
logic load_tag;
logic load_valid;
logic [s_line-1:0] mem_rdata_line;
logic [31:0] addr_reg;
logic [31:0] current_address;
logic addr_mux_sel;
logic [31:0] access_addr;

assign load_data    = load;
assign load_tag     = load;
assign load_valid   = load;
// assign mem_rdata_cpu = mem_rdata_line[(32*access_addr[4:2]) +: 32];


always_comb begin
    if(~load) current_address = mem_address;
    else current_address = addr_reg;
end

always_ff @(posedge clk) begin
    if(rst) begin
        addr_reg <= '0; 
    end
    else begin
        // if() begin // what the fuck is going on
        addr_reg <= current_address;
        // end
    end 
end 

always_comb begin
    // access_addr = addr_reg;
    access_addr = addr_reg;
    mem_rdata_cpu = mem_rdata_line[(32*access_addr[addr_sel:2]) +: 32];
end

icache_bk_datapath  #(.s_offset(s_offset), .s_index(s_index))
icache_bk_datapath(
    .clk(clk),
    .rst(rst),

    /* signals from CPU */
    .mem_address(access_addr),
    .mem_rdata256(mem_rdata_line),
    
    /* signals for main memory */
    .pmem_rdata(pmem_rdata),
    .pmem_address(pmem_address),

    // to control
    .is_hit(is_hit),

    // from control
    .load_data(load_data),
    .load_tag(load_tag),
    .load_valid(load_valid),
    .valid_in(valid_in)
);

icache_bk_control  icache_bk_control(
    .clk(clk),
    .rst(rst),
    .hit(is_hit),
    .load(load),
    .valid_in(valid_in),
    .mem_read(mem_read),
    .mem_resp(mem_resp),
    .pmem_resp(pmem_resp),
    .pmem_read(pmem_read),
    .addr_mux_sel(addr_mux_sel)
);


endmodule