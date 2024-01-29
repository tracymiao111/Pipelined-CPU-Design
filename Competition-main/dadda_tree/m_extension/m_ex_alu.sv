module m_extension_alu
import m_extension::*;
(
    input logic clk,
    input logic rst,
    
    // data input and opcode (operation)
    input logic [31:0]  rs1_data_i,
    input logic [31:0]  rs2_data_i,
    input m_funct3      funct3,
    input logic         m_alu_active,   // used to enable mul, div, rem, 1: unit is active, do work; 0: do not do work
    // results
    output logic m_ex_alu_done,
    output logic [31:0] rd_data_o
);


logic is_mul, mul_done;
logic [31:0] mul_out;

logic div_done;
logic [31:0] quotient, remainder;

logic rst_or_not_act;   // if rst is on or m_alu is not active

assign is_mul = (funct3[2] == '0); // if the operation is not mul, then it is div or rem
assign m_ex_alu_done = mul_done | div_done | ~(m_alu_active); // if no operation is performing, there will be no stalls

assign rst_or_not_act = rst | ~(m_alu_active);

multiplier multiplier
(   
    // input
    .clk(clk),
    .rst(rst_or_not_act),
    .rs1_data(rs1_data_i),
    .rs2_data(rs2_data_i),
    .funct3(funct3),
    .is_mul(is_mul),

    // output
    .mul_done(mul_done),
    .mul_out(mul_out)
);

divider divider
(
    // input
    .clk(clk),
    .rst(rst_or_not_act),
    .dividend(rs1_data_i),    // rs1, 
    .divisor(rs2_data_i),     // rs2, /*** dividend / divisor ***/
    .start(~is_mul),
    .funct3(funct3),

    // output
    .div_done(div_done),      
    .quotient(quotient),
    .remainder(remainder)
);

always_comb begin
    case(funct3)
        mul, mulh, mulhsu, mulhu: rd_data_o = mul_out;
        div, divu: rd_data_o = quotient;
        rem, remu: rd_data_o = remainder;
        default: rd_data_o = mul_out;
    endcase
end

endmodule;