module l2_bus_adapter
#(
    parameter l2_cacheline = 256,
    parameter l2_wmask_len = l2_cacheline >> 3,
    parameter arbiter_cacheline = 128,
    parameter arbiter_wmask_len = arbiter_cacheline >> 3,
    parameter extend_size = l2_cacheline / arbiter_cacheline,
    parameter shift_bit_len = $clog2(extend_size)
)
(
    // input logic [shift_bit_len-1:0] shift_bit,
    input logic shift_bit,
    input logic [arbiter_cacheline-1 :0] arbiter_wdata,  // data arbiter send to L2
    input logic [arbiter_wmask_len-1:0] arbiter_wmask,
    output logic [arbiter_cacheline-1 :0] arbiter_rdata, // data arbiter request from L2

    input logic [l2_cacheline-1 :0] l2_mem_rdata,       // data coming from L2, pass to arbiter
    output logic [l2_cacheline-1 :0] l2_mem_wdata,      // processed arbiter data to L2
    output logic [l2_wmask_len-1:0] l2_byte_enable           // 32 bit mask for 256 cacheline
);

 assign l2_mem_wdata = {(extend_size){arbiter_wdata}};
 assign l2_byte_enable = { {(l2_wmask_len - arbiter_wmask_len){1'b0}} , arbiter_wmask} << (shift_bit*arbiter_wmask_len); 
 assign arbiter_rdata = l2_mem_rdata[(arbiter_cacheline * shift_bit) +: arbiter_cacheline]; 
// always_comb begin
//     if(shift_bit) begin
//         l2_byte_enable = {16'hFFFF, 16'h0};
//         arbiter_rdata = l2_mem_rdata[255:128];
//     end 
//     else begin
//         l2_byte_enable = {16'h0, 16'hFFFF};
//         arbiter_rdata = l2_mem_rdata[127:0];
//     end
// end

endmodule
