module cache_control (
    input  logic clk,
    input  logic rst,
    /******************* with CPU ***********************/
    input  logic mem_read,
    input  logic mem_write,
    output logic mem_resp,
    /******************* with MEM ***********************/
    input  logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,
    /***************** with DATAPATH *********************/
    input  logic is_hit,
    input  logic is_dirty,
    output logic is_allocate,
    output logic use_replace,
    output logic load_data,
    output logic load_tag,
    output logic load_valid,
    output logic load_dirty,
    output logic load_plru,
    output logic valid_in,
    output logic dirty_in
);

enum int unsigned{
    /* List of states */
    IDLE, TAG_COMPARE, ALLOCATE, WRITE_BACK
} state, next_state;

function void initialization();
    {mem_resp, pmem_read, pmem_write}              = 3'b0;
    {load_data, load_tag, load_valid, load_dirty}  = 4'b0;
    {is_allocate, use_replace}                     = 2'b0;
    {valid_in, dirty_in}                           = 2'b0;
endfunction

function void TAG_COMPARE_ACTIONS();
    {load_plru, mem_resp}             = {2{is_hit}};
    {load_dirty, load_data, dirty_in} = {3{is_hit && mem_write}};
endfunction

function void ALLOCATE_ACTIONS();
    {valid_in, dirty_in}                           = 2'b10;
    {load_data, load_tag, load_valid, load_dirty}  = 4'hF;
    {is_allocate, pmem_read, use_replace}          = 3'b111;
endfunction

function void WRITE_BACK_ACTIONS();
    {use_replace, pmem_write} = 2'b11;
endfunction

always_comb begin
    initialization();
    case (state)
        IDLE       : ;
        TAG_COMPARE: TAG_COMPARE_ACTIONS();
        ALLOCATE   : ALLOCATE_ACTIONS();
        WRITE_BACK : WRITE_BACK_ACTIONS();
        default    : ;
    endcase
end

always_comb begin
    next_state = state;
    case (state)
        IDLE       : next_state = (mem_read || mem_write)? TAG_COMPARE : IDLE;
        TAG_COMPARE: next_state = is_hit? IDLE : (is_dirty? (WRITE_BACK) : (ALLOCATE));
        ALLOCATE   : next_state = pmem_resp? TAG_COMPARE : ALLOCATE;
        WRITE_BACK : next_state = pmem_resp? ALLOCATE : WRITE_BACK;
        default    : next_state = IDLE; 
    endcase
end

always_ff @(posedge clk) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
end

endmodule : cache_control
