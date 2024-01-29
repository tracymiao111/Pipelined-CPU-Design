// simple divider ========================================================================
module divider
import rv32i_types::*;
(
    input   logic clk,
    input   logic rst,
    input   logic [31:0] dividend,    // rs1, 
    input   logic [31:0] divisor,     // rs2, /*** dividend / divisor ***/
    input   logic        start,
    input   m_funct3_t   funct3,
    output  logic       div_done,      
    output  logic [31:0] quotient,
    output  logic [31:0] remainder
);


enum logic[2:0]{
    idle, shift, done
} state, next_state;

logic [63:0] data, next_data;
logic [31:0] divisor_reg, divisor_reg_in;
logic [31:0] count, next_count;
// logic [31:0] neg_temp;

// logic ready, busy;
logic complete;
// logic signed_op;
// logic overflow_on;
// logic should_neg;
// logic next_should_neg;
// assign signed_op = (funct3 == div || funct3 == rem); // div and rem are signed operation
// assign overflow_on = (dividend == 32'h80000000 && divisor == 32'hFFFFFFFF);
// assign neg_temp = ~(dividend) + 1'b1;

always_comb begin
    next_state = state;
    next_data = data;
    next_count = count;
    divisor_reg_in = divisor_reg;
    complete = 1'b0;
    // next_should_neg = should_neg;
    
    if(rst) begin
        divisor_reg_in = '0;
        next_state = idle;
        next_data = '0;
        next_count = '0;
        // next_should_neg = '0;
    end
    else begin
        case(state)
            idle: begin
                // next_should_neg = '0;
                if(start == 1'b1) begin
                    if(divisor == 32'b0) begin
                        next_state = done;
                        next_data = {dividend, 32'hFFFFFFFF};
                        // complete = 1'b1;
                    end
                    // else if(signed_op && overflow_on) begin
                    //     next_state = done;
                    //     next_data = {32'b0, 32'h80000000};
                    // end
                    else begin
                        divisor_reg_in = divisor;
                        next_state = shift;
                        next_data = {32'b0, dividend};
                        next_count = 32'd32;
                        // if(signed_op) begin
                        //     next_should_neg = divisor[31] ^ dividend[31];
                        //     if(divisor[31]) begin
                        //         divisor_reg_in = ~divisor + 1'b1;
                        //     end
                        //     if(dividend[31]) begin
                        //         neg_temp = ~(dividend) + 1'b1;
                        //         next_data = {32'b0, neg_temp[31:0]};
                        //     end
                        // end
                    end
                end
            end
            shift: begin
                next_data = {data[62:0], 1'b0};
                next_count = count - 1'b1;
                if(data[62:31] >= divisor_reg) begin
                    next_data[0] = 1'b1;
                    next_data[63:32] = data[62:31] - divisor_reg;
                end
                if(count == 32'd1)begin
                    next_state = done;
                end
            end
            done: begin
                complete = 1'b1;
                next_state = idle;
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    state <= next_state;
    data <= next_data;
    count <= next_count;
    divisor_reg <= divisor_reg_in;
    // should_neg <= next_should_neg;
end

assign div_done = complete;
// assign quotient = complete ? data[31:0] : '0;
// assign remainder = complete ? data[63:32] : '0;


always_comb begin
    quotient = '0;
    remainder = '0;
    if(complete) begin
        quotient = data[31:0];
        remainder = data[63:32];
        
        // dependency matters
        // if(~(divisor == 32'b0 || (signed_op && overflow_on))) begin
            // if(should_neg) begin
            //     quotient = (~data[31:0]) + 1'b1;
            // end
            // if(dividend[31] && signed_op) begin
            //     remainder = (~data[63:32]) + 1'b1;
            // end 
        // end
        // else if(divisor[31]) begin
        //     remainder = (~data[63:32]) + 1'b1;
        // end
        // if(divisor == 32'b0) begin
        //     remainder = dividend;
        //     quotient = 32'hFFFFFFFF;
        // end
        // else if(signed_op && overflow_on) begin
        //     remainder = '0;
        //     quotient = 32'h80000000;
        // end
    end
end

endmodule
// ===========================================================
