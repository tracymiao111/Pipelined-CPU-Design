// half adder, 1 bit
module HA_C(  
    input logic A_i,
    input logic B_i,
    output logic S_o,
    output logic c_out
);

assign S_o = A_i ^ B_i;
assign c_out = A_i & B_i;

endmodule

// full adder, 1 bit
module FA_C(
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

// half adder, 1 bit
module HA_F(
    input logic clk,
    input logic A_i,
    input logic B_i,
    output logic S_o,
    output logic c_out
);
logic s_ff;
logic c_ff;

always_ff @(posedge clk) begin
    s_ff <= A_i ^ B_i;
    c_ff <= A_i & B_i;
end

// assign S_o = A_i ^ B_i;
// assign c_out = A_i & B_i;
assign S_o = s_ff;
assign c_out = c_ff;

endmodule

// full adder, 1 bit
module FA_F(
    input logic clk,
    input logic A_i,
    input logic B_i,
    input logic c_in,
    output logic S_o,
    output logic c_out
);

logic s_ff, c_ff;

always_ff @(posedge clk) begin
    s_ff <= A_i ^ B_i ^ c_in;
    c_ff <= (A_i & B_i) | (A_i & c_in) | (B_i & c_in);
end

assign S_o = s_ff;
assign c_out = c_ff;

// assign S_o = A_i ^ B_i ^ c_in;
// // assign c_out = (A_i & B_i) | (c_in & (A_i ^ B_i));
// assign c_out = (A_i & B_i) | (A_i & c_in) | (B_i & c_in);

endmodule


