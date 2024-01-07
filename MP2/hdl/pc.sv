module pc 
import rv32i_types::*;
(
    input clk_i,
    input rst_i,
    input load_i,
    input rv32i_word pc_in,
    output rv32i_word pc_out 
);

rv32i_word pc_temp;

always_ff @(posedge clk_i) begin
    if (rst_i == 1'b1) begin
        pc_temp <= 32'h40000000;
    end else if (load_i == 1'b1) begin
        pc_temp <= pc_in;
    end else begin
        ;
    end
end

assign pc_out = pc_temp;
    
endmodule