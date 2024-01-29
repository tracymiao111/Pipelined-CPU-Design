module multiplier_control
import m_extension::*;
(
    input logic     clk,
    input logic     rst,
    input logic     is_mul,
    // output logic    should_load,
    // output logic    should_prop,
    output logic    done
);

logic done_count;
logic [1:0] counter;
enum logic[2:0]{
    IDLE, IN_OP, DONE
} state, next_state;

assign done_count = (counter == 2'b11);
// state transition
always_comb begin
    next_state = state;
    if(rst) begin
        next_state = IDLE;
    end 
    else begin
        unique case(state)
            IDLE: begin 
                if(is_mul) begin
                    next_state = IN_OP;
                end
            end
            IN_OP: begin
                if(done_count) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
end

// signal control
always_comb begin
    // should_load = 1'b0;
    // should_prop = 1'b0;
    done = 1'b0;
    unique case(state)
        // IDLE: begin
        //     should_load = 1'b1;
        // end
        // IN_OP: begin
        //     should_load = 1'b0;
        //     should_prop = 1'b1;
        // end
        DONE: begin
            done = 1'b1;
        end
        default:;
    endcase 
end

always_ff @(posedge clk) begin
    if(state == IN_OP) begin
        counter <= counter + 1'b1;
    end 
    else begin
        counter <= counter + 1'b1;
    end 
end

always_ff @(posedge clk) begin
    state <= next_state;
end

endmodule
