module eviction_buffer 
#(
    parameter cacheline_size = 256
)
(
    input clk, 
    input rst, 
    /*================= with L1 Cache ==================*/
    input logic [31:0] from_dcache_address,
    input logic from_dcache_write, 
    input logic from_dcache_read, 
    input logic [cacheline_size-1:0] from_dcache_wdata,
    output logic [cacheline_size-1:0] to_dcache_rdata, 
    output logic to_dcache_resp, 
    /*================= with arbiter ==================*/
    input logic [cacheline_size-1:0] from_arbiter_rdata, 
    input logic from_arbiter_resp, 
    output logic to_arbiter_write, 
    output logic to_arbiter_read, 
    output logic [31:0] to_arbiter_address,
    output logic [cacheline_size-1:0] to_arbiter_wdata
);

logic [31:0] address, address_next;
logic [cacheline_size-1:0] data, data_next;
logic wb_flag; 

enum int unsigned {IDLE, READ, WB} state, next_state; 

function void set_defaults();
    to_dcache_rdata = '0; 
    to_dcache_resp = 1'b0; 
    to_arbiter_write = 1'b0;
    to_arbiter_read = 1'b0; 
    to_arbiter_address = 32'b0; 
    to_arbiter_wdata = '0; 
    address_next = address;
    data_next = data;
endfunction

function void idle_actions();
    if (from_dcache_write) begin 
        to_dcache_resp = 1'b1; 
        address_next = from_dcache_address; 
        data_next = from_dcache_wdata; 
    end else begin
        ;
    end
endfunction

function void read_actions();
    to_dcache_rdata = from_arbiter_rdata; 
    to_dcache_resp = from_arbiter_resp; 
    to_arbiter_address = from_dcache_address; 
    to_arbiter_read = 1'b1; 
endfunction

function void wb_actions();
    to_arbiter_wdata = data; 
    to_arbiter_address = address;
    to_arbiter_write = 1'b1;   
endfunction

always_comb begin 
    set_defaults();
    case(state)
        IDLE: idle_actions();
        READ: read_actions();
        WB: wb_actions();
        default:;
    endcase 
end 

always_comb begin 
    next_state = state;
    case(state)
        IDLE: next_state = from_dcache_read ? READ : IDLE;
        READ: next_state = from_arbiter_resp ? (wb_flag ? WB : IDLE) : READ;
        WB: next_state = from_arbiter_resp ? IDLE : WB;
    endcase 
end 

always_ff @(posedge clk) begin 
    if (rst) begin
        state <= IDLE; 
        wb_flag <= 1'b0; 
        address <= 32'd0; 
        data <= '0;
    end
    else begin
        state <= next_state;
        address <= address_next; 
        data <= data_next; 
        if (state == WB) begin
            wb_flag <= 1'b0;
        end else if (state == IDLE && from_dcache_write) begin
            wb_flag <= 1'b1;
        end
    end 
end



endmodule : eviction_buffer


