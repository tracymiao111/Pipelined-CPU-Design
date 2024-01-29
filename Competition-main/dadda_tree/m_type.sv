package m_extension;

typedef enum logic[2:0]{
    mul     = 3'b000,       // multiply two operands, output the lower 32 bits
    mulh    = 3'b001,
    mulhsu  = 3'b010,
    mulhu   = 3'b011,
    div     = 3'b100,
    divu    = 3'b101,
    rem     = 3'b110,
    remu    = 3'b111
}m_funct3;

endpackage