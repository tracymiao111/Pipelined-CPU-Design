
module plru_update(  
    input logic [0 : 0] hit_way,
    output logic [0 : 0] new_plru_bits
);
 
always_comb begin
    case(hit_way)
        1'd0: new_plru_bits = {~hit_way[0]};
        1'd1: new_plru_bits = {~hit_way[0]};

        default: new_plru_bits = 1'b0;
    endcase
end
endmodule
