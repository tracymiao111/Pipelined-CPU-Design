module cmp
import rv32i_types::*; 
(
    input branch_funct3_t cmpop_i,
    input rv32i_word a_i,
    input rv32i_word b_i,
    output logic cmp_o
);

always_comb begin: comparator
    unique case (cmpop_i)
        beq    : cmp_o  = (a_i == b_i);
        bne    : cmp_o  = (a_i != b_i);
        blt    : cmp_o  = ($signed(a_i) < $signed(b_i));
        bge    : cmp_o  = ($signed(a_i) >= $signed(b_i));
        bltu   : cmp_o  = (a_i < b_i);
        bgeu   : cmp_o  = (a_i >= b_i);
        default: cmp_o  = 1'b0;
    endcase
end: comparator
    
endmodule