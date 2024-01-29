module icache_bk_array
#(  
    parameter s_index = 3,
    parameter num_set = 2**s_index,
    parameter datawidth = 1
)(
  input logic clk,
  input logic rst,
  input logic load,
  input logic [s_index-1:0] index,
  input logic [datawidth-1:0] datain,
  output logic [datawidth-1:0] dataout
);

logic [datawidth-1:0] data [num_set];

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
        if(load) begin
            data[index] <= datain;
        end
    end
end 




endmodule