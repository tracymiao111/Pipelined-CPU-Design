// half adder, 1 bit
module HA(  
    input logic A_i,
    input logic B_i,
    output logic S_o,
    output logic c_out
);

assign S_o = A_i ^ B_i;
assign c_out = A_i & B_i;

endmodule

// full adder, 1 bit
module FA(
    input logic A_i,
    input logic B_i,
    input logic c_in,
    output logic S_o,
    output logic c_out
);

assign S_o = A_i ^ B_i ^ c_in;
// assign c_out = (A_i & B_i) | (c_in & (A_i ^ B_i));
assign c_out = (A_i & B_i) | (A_i & c_in) | (B_i & c_in);

endmodule