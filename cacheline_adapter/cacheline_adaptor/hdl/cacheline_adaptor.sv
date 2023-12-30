module cacheline_adaptor (
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

    /* state description */
    enum int unsigned {
        IDLE, READ_BURST1, WRITE_BURST1, READ_BURST2, WRITE_BURST2, COMPLETED
    } state;

    /* counter & buffer */
    logic [1:0] burst_counter; 
    logic [255:0] line_buffer; 
    logic [31:0] address_buffer;

    /* default & output assignments */
    always_comb begin 
        {resp_o, write_o, read_o} = 3'b000;
        address_o = address_buffer;
        line_o = line_buffer;
        burst_o = line_buffer[64*burst_counter +: 64];

        case (state)
            READ_BURST1, READ_BURST2: read_o = 1'b1;
            WRITE_BURST1, WRITE_BURST2: write_o = 1'b1;
            COMPLETED: resp_o = 1'b1;
        endcase
    end

    /* state transition description */
    always_ff @(posedge clk) begin
        if (~reset_n) begin
            state <= IDLE;
        end else begin
            unique case (state)
                IDLE: begin
                    address_buffer <= address_i;
                    if (read_i) begin
                        state <= READ_BURST1;
                        burst_counter <= 2'b0;
                    end else if (write_i) begin
                        state <= WRITE_BURST1;
                        line_buffer <= line_i;
                        burst_counter <= 2'b0;
                    end
                end

                READ_BURST1: begin
                    if (resp_i) begin
                        state <= READ_BURST2;
                        burst_counter <= 2'b01;
                        line_buffer[63:0] <= burst_i;
                    end
                end

                READ_BURST2: begin
                    line_buffer[64*burst_counter +: 64] <= burst_i;
                    burst_counter <= burst_counter + 1'b1;
                    if (burst_counter == 2'b11) begin
                        state <= COMPLETED;
                    end 
                end

                WRITE_BURST1: begin
                    if (resp_i) begin
                        state <= WRITE_BURST2;
                        burst_counter <= 2'b01;
                    end
                end

                WRITE_BURST2: begin
                    burst_counter <= burst_counter + 1'b1;
                    if (burst_counter == 2'b11) begin
                        state <= COMPLETED;
                    end
                end

                COMPLETED: state <= IDLE;
            endcase
        end
    end

endmodule
