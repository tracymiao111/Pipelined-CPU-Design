module l2_cache_control (
    input logic clk,        // clock
    input logic rst,      // rst
    // memory response
    input logic pmem_resp,
    output logic mem_resp,

    // memory read and write
    input logic mem_read,
    input logic mem_write,
    output logic pmem_read,
    output logic pmem_write,
    
    // input to FSM, state transition purpose
    input logic is_hit, 
    // input logic is_valid, 
    input logic is_dirty,

    // load signals
    output logic load_data, 
    output logic load_tag, 
    output logic load_dirty, 
    output logic load_valid, 
    output logic load_plru,

    // valid input and dirty input to the array
    output logic valid_in, 
    output logic dirty_in,
    
    // state indicator
    output logic is_allocate,

    // replacement in use
    output logic use_replace
);

// states
enum int unsigned{
    IDLE, HIT_CHECK, ALLOCATE, WRITE_BACK
}state, next_states;

// default signals
function void set_default_output();
    load_data = 1'b0;
    load_tag = 1'b0;
    load_dirty = 1'b0;
    load_valid = 1'b0;
    load_plru = 1'b0;
    pmem_write = 1'b0;
    pmem_read = 1'b0;
    valid_in = 1'b0;
    dirty_in = 1'b0;
    is_allocate = 1'b0;
    use_replace = 1'b0;
    mem_resp = 1'b0;
endfunction

// allocate state output signals
function void allocate_output();
    is_allocate = 1'b1; // allocate state indicator
    pmem_read = 1'b1;   // issue read to main memory
    load_data = 1'b1;   // ready to load data
    load_tag = 1'b1;    // ready to load tag
    load_valid = 1'b1;  // ready to load valid
    load_dirty = 1'b1;  // ready to load dirty
    use_replace = 1'b1; // replacement in use
    valid_in = 1'b1;    // valid cache coming in
    dirty_in = 1'b0;    // clean cache coming in
endfunction

// state outputs
always_comb begin
    set_default_output();
    unique case(state)
        IDLE:;
        HIT_CHECK: begin // see if there is a hit or not
            if(is_hit == 1'b1) begin
                load_plru = 1'b1;
                mem_resp = 1'b1;
                if(mem_write == 1'b1) begin // cp1 should never trigger this, if it does, ooof something is wrong
                    load_dirty = 1'b1;
                    dirty_in = 1'b1;
                    load_data = 1'b1;
                end 
            end
        end
        ALLOCATE: allocate_output();
        WRITE_BACK: begin
            use_replace = 1'b1;
            pmem_write = 1'b1; 
        end 
        default:;
    endcase

end 

// state actions
always_comb begin
    next_states = state; // force state to be the current state
    if(rst) begin // reset signals
        next_states = IDLE;
    end
    else begin
        unique case(state)
            IDLE: begin // state idle here
                if(mem_read ^ mem_write) begin
                    next_states = HIT_CHECK;
                end 
            end 
            HIT_CHECK: begin // state hit_check here
                if(is_hit == 1'b1) begin
                    next_states = IDLE;
                end
                else begin 
                    if(is_dirty == 1'b1) begin
                        next_states = WRITE_BACK;
                    end
                    else begin
                        next_states = ALLOCATE;
                    end 
                end 
            end 
            ALLOCATE: begin // state allocate here
                if(pmem_resp == 1'b1) begin // if memory did not response, stay in ALLOCATE
                    next_states = HIT_CHECK;
                end
            end
            WRITE_BACK: begin
                if(pmem_resp == 1'b1) begin
                    next_states = ALLOCATE;
                end
            end
            default: next_states = IDLE;
        endcase 
    end 
end

// state tracking
always_ff @(posedge clk) begin
    state <= next_states;
end

endmodule : l2_cache_control
