module cmp 
import rv32i_types::*;
(
    input rv32i_word a,
    input rv32i_word b,
    input branch_funct3_t cmpop,
    output logic br_en
);

    always_comb 
    begin
        unique case (cmpop)
            beq: br_en = (a == b);
            bne: br_en = (a != b);
            blt: br_en = ($signed(a) <  $signed(b));
            bge: br_en = ($signed(a) >= $signed(b));
            bltu: br_en = (a < b);
            bgeu: br_en = (a >= b);
            default: br_en = (a == b);
        endcase
    end

endmodule : cmp