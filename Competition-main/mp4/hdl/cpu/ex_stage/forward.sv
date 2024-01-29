module forward_unit
import rv32i_types::*;
(
    /* inputs to determine data hazards */
    input rv32i_reg ex_to_mem_rd,
    input rv32i_reg mem_to_wb_rd,
    input rv32i_reg id_to_ex_rs1,
    input rv32i_reg id_to_ex_rs2,
    input logic ex_to_mem_load_regfile,
    input logic mem_to_wb_load_regfile,
    /* output for ALU */

    output data_forward_t forwardA_o,
    output data_forward_t forwardB_o    
);

// local variables
logic[1:0] fd_A, fd_B;

// assignments
assign forwardA_o = data_forward_t'(fd_A);
assign forwardB_o = data_forward_t'(fd_B);

always_comb begin
    fd_A = 2'b00;
    fd_B = 2'b00;

    if(ex_to_mem_load_regfile && ex_to_mem_rd != 0 && ex_to_mem_rd == id_to_ex_rs1)begin
        fd_A = 2'b10;
    end

    if(ex_to_mem_load_regfile && ex_to_mem_rd != 0 && ex_to_mem_rd == id_to_ex_rs2)begin
        fd_B = 2'b10;
    end

    if(mem_to_wb_load_regfile && mem_to_wb_rd != 0 && !(ex_to_mem_load_regfile && ex_to_mem_rd != 0 && ex_to_mem_rd == id_to_ex_rs1) && mem_to_wb_rd == id_to_ex_rs1)begin
        fd_A = 2'b01;
    end

    if(mem_to_wb_load_regfile && mem_to_wb_rd != 0 && !(ex_to_mem_load_regfile && ex_to_mem_rd != 0 && ex_to_mem_rd == id_to_ex_rs2) && mem_to_wb_rd == id_to_ex_rs2)begin
        fd_B = 2'b01;
    end

end


endmodule
