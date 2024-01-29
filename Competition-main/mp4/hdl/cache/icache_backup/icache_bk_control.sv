module icache_bk_control(
    input logic clk,
    input logic rst,
    
    // icache datapath
    input logic hit,
    output logic load,
    output logic valid_in,
    output logic addr_mux_sel,
    
    // from cpu
    input logic mem_read,

    // to cpu
    output logic mem_resp,

    // from arbitor
    input logic pmem_resp,

    // to arbitor
    output logic pmem_read
);

enum logic[31:0]{
    check_hit,
    read_mem
} state, next_state;

// state action
always_comb begin
    pmem_read = 1'b0;
    mem_resp = 1'b0;
    load = 1'b0;
    valid_in = 1'b0;
    addr_mux_sel = 1'b0;
    case(state)
        check_hit: begin
            if(mem_read) begin
                if(hit) begin // cache hits
                    mem_resp = 1'b1;
                end 
            end
        end
        read_mem: begin
            pmem_read = 1'b1;
            load = 1'b1;
            if(pmem_resp) begin
                valid_in = 1'b1;
            end
        end
        default:;
    endcase
end

// state transition
always_comb begin
    next_state = state;
    if(rst) begin
        next_state = check_hit;
    end
    else begin
        case(state)
            check_hit: begin // always hit checking
                if(!hit && mem_read) begin
                    next_state = read_mem;
                end
            end
            
            read_mem: begin // bring in data block
                if(pmem_resp) begin
                    next_state = check_hit;
                end
            end
            default:;
        endcase
    end
end

// clk driven
always_ff @(posedge clk) begin
    state <= next_state;
end

endmodule