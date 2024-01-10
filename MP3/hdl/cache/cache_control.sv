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
    input  logic hit_sig,
    input  logic dirty_sig,
    output logic allo_sig,
    output logic rep_sig,
    output logic load_data,
    output logic load_tag,
    output logic load_valid,
    output logic load_dirty,
    output logic load_plru,
    output logic valid_i,
    output logic dirty_i
);

enum int unsigned{
    /* List of states */
    IDLE, TAG_COMPARE, ALLOCATE, WRITE_BACK
} state, next_state;

function void initialization();
    {mem_resp, pmem_read, pmem_write}                         = 3'b0;
    {load_data, load_tag, load_valid, load_dirty, load_plru}  = 5'b0;
    {allo_sig, rep_sig}                                       = 2'b0;
    {valid_i, dirty_i}                                        = 2'b0;
endfunction

function void TAG_COMPARE_ACTIONS();
    {load_plru, mem_resp}             = {2{hit_sig}};
    {load_dirty, load_data, dirty_i}  = {3{hit_sig && mem_write}};
endfunction

function void ALLOCATE_ACTIONS();
    {valid_i, dirty_i}                             = 2'b10;
    {load_data, load_tag, load_valid, load_dirty}  = 4'hF;
    {allo_sig, pmem_read, rep_sig}                 = 3'b111;
endfunction

function void WRITE_BACK_ACTIONS();
    {rep_sig, pmem_write} = 2'b11;
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
        TAG_COMPARE: next_state = hit_sig? IDLE : (dirty_sig? (WRITE_BACK) : (ALLOCATE));
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
