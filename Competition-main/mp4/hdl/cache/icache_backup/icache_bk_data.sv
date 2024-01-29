module icache_bk_data_array
#(
    parameter s_offset = 5,
    parameter s_index = 3,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_set = 2**s_index
)
(
    input   logic           clk,
    input   logic           rst,
    input   logic           web,
    input   logic [s_index-1:0]     index,
    input   logic [s_line-1:0]   datain,
    output  logic [s_line-1:0]   dataout
);

logic [s_line-1:0] data[num_set]; 
// = '{8{'0}}; 

always_comb begin
    dataout = data[index];
end 

always_ff @(posedge clk) begin
    if(rst) begin
        for(int i = 0; i < num_set; ++i) begin
            data[i] <= '0;
        end 
    end
    else begin
        if(web) begin
            data[index] <= datain;
        end
    end
end


endmodule