
// module plru_update(  
//     input logic [2 : 0] hit_way,
//     input logic [6 : 0] plru_bits,
//     output logic [6 : 0] new_plru_bits
// );
 
// always_comb begin
//     case(hit_way)
//         3'd0: new_plru_bits = {plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[0], plru_bits[2], ~hit_way[1], ~hit_way[2]};
//         3'd1: new_plru_bits = {plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[0], plru_bits[2], ~hit_way[1], ~hit_way[2]};
//         3'd2: new_plru_bits = {plru_bits[6], plru_bits[5], ~hit_way[0], plru_bits[3], plru_bits[2], ~hit_way[1], ~hit_way[2]};
//         3'd3: new_plru_bits = {plru_bits[6], plru_bits[5], ~hit_way[0], plru_bits[3], plru_bits[2], ~hit_way[1], ~hit_way[2]};
//         3'd4: new_plru_bits = {plru_bits[6], ~hit_way[0], plru_bits[4], plru_bits[3], ~hit_way[1], plru_bits[1], ~hit_way[2]};
//         3'd5: new_plru_bits = {plru_bits[6], ~hit_way[0], plru_bits[4], plru_bits[3], ~hit_way[1], plru_bits[1], ~hit_way[2]};
//         3'd6: new_plru_bits = {~hit_way[0], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[1], plru_bits[1], ~hit_way[2]};
//         3'd7: new_plru_bits = {~hit_way[0], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[1], plru_bits[1], ~hit_way[2]};

//         default: new_plru_bits = 7'b0000000;
//     endcase
// end
// endmodule



// module plru_update(  
//     input logic [1 : 0] hit_way,
//     input logic [2 : 0] plru_bits,
//     output logic [2 : 0] new_plru_bits
// );
 
// always_comb begin
//     case(hit_way)
//         2'd0: new_plru_bits = {plru_bits[2], ~hit_way[0], ~hit_way[1]};
//         2'd1: new_plru_bits = {plru_bits[2], ~hit_way[0], ~hit_way[1]};
//         2'd2: new_plru_bits = {~hit_way[0], plru_bits[1], ~hit_way[1]};
//         2'd3: new_plru_bits = {~hit_way[0], plru_bits[1], ~hit_way[1]};

//         default: new_plru_bits = 3'b000;
//     endcase
// end
// endmodule


// module plru_update(  
//     input logic [0 : 0] hit_way,
//     input logic [0 : 0] plru_bits,
//     output logic [0 : 0] new_plru_bits
// );
 
// always_comb begin
//     case(hit_way)
//         1'd0: new_plru_bits = {~hit_way[0]};
//         1'd1: new_plru_bits = {~hit_way[0]};

//         default: new_plru_bits = 1'b0;
//     endcase
// end
// endmodule


// module plru_update(  
//     input logic [3 : 0] hit_way,
//     input logic [14 : 0] plru_bits,
//     output logic [14 : 0] new_plru_bits
// );
 
// always_comb begin
//     case(hit_way)
//         4'd0: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], ~hit_way[0], plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[1], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd1: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], ~hit_way[0], plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[1], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd2: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], ~hit_way[0], plru_bits[7], plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[1], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd3: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], ~hit_way[0], plru_bits[7], plru_bits[6], plru_bits[5], plru_bits[4], ~hit_way[1], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd4: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], ~hit_way[0], plru_bits[8], plru_bits[7], plru_bits[6], plru_bits[5], ~hit_way[1], plru_bits[3], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd5: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], ~hit_way[0], plru_bits[8], plru_bits[7], plru_bits[6], plru_bits[5], ~hit_way[1], plru_bits[3], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd6: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], ~hit_way[0], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], plru_bits[5], ~hit_way[1], plru_bits[3], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd7: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], plru_bits[11], ~hit_way[0], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], plru_bits[5], ~hit_way[1], plru_bits[3], plru_bits[2], ~hit_way[2], ~hit_way[3]};
//         4'd8: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], ~hit_way[0], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], ~hit_way[1], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd9: new_plru_bits = {plru_bits[14], plru_bits[13], plru_bits[12], ~hit_way[0], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], ~hit_way[1], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd10: new_plru_bits = {plru_bits[14], plru_bits[13], ~hit_way[0], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], ~hit_way[1], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd11: new_plru_bits = {plru_bits[14], plru_bits[13], ~hit_way[0], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], plru_bits[6], ~hit_way[1], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd12: new_plru_bits = {plru_bits[14], ~hit_way[0], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], ~hit_way[1], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd13: new_plru_bits = {plru_bits[14], ~hit_way[0], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], ~hit_way[1], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd14: new_plru_bits = {~hit_way[0], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], ~hit_way[1], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};
//         4'd15: new_plru_bits = {~hit_way[0], plru_bits[13], plru_bits[12], plru_bits[11], plru_bits[10], plru_bits[9], plru_bits[8], plru_bits[7], ~hit_way[1], plru_bits[5], plru_bits[4], plru_bits[3], ~hit_way[2], plru_bits[1], ~hit_way[3]};

//         default: new_plru_bits = 15'b000000000000000;
//     endcase
// end
// endmodule