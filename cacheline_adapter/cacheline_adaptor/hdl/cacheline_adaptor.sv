module cacheline_adaptor
(
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

    /* list all states needed for cacheline adaptor */
    enum int unsigned{
        IDLE, READ_1, WRITE_1, READ_2, WRITE_2, FINISHED
    } state;

    logic [1:0] counter;
    logic [255:0] line_temp; //the buffer
    logic [31:0] address_temp;


    function void set_defaults();
        resp_o = 1'b0;
        write_o = 1'b0;
        read_o = 1'b0;
    endfunction

    always_comb begin 
        set_defaults();
        address_o = address_temp;
        line_o = line_temp;
        burst_o = line_temp[64*counter +: 64];
        // read_o = (state == (READ_1||READ_2));
        // write_o = (state == (WRITE_1||WRITE_2));
        // resp_o = (state == FINISHED);
        case (state)
            READ_1: read_o = 1'b1;
            READ_2: read_o = 1'b1;
            WRITE_1: write_o = 1'b1;
            WRITE_2: write_o = 1'b1;
            FINISHED: resp_o = 1'b1;
            default: set_defaults();
        endcase
    end

    always_ff @(posedge clk) begin
        if (~reset_n) begin
            state <= IDLE;
        end else begin
            unique case (state)
                IDLE: begin
                    address_temp <= address_i;
                    if (read_i) begin
                        state <= READ_1;
                        counter <= 2'b0;
                    end else if (write_i) begin
                        state <= WRITE_1;
                        line_temp <= line_i;
                        counter <= 2'b0;
                    end else begin
                        ;
                    end
                end

                READ_1: begin
                    if (resp_i) begin
                        state <= READ_2;
                        counter <= 2'b01;
                        line_temp[63:0] <= burst_i;
                    end else begin
                        ;
                    end
                end

                READ_2: begin
                    if (counter == 2'b11) begin
                        state <= FINISHED;
                    end 
                    line_temp[64*counter +: 64] <= burst_i;
                    counter <= counter + 1'b1;
                end

                WRITE_1: begin
                    if (resp_i) begin
                        state <= WRITE_2;
                        counter <= 2'b01;
                    end else begin
                        ;
                    end
                end

                WRITE_2: begin
                    if (counter == 2'b11) begin
                        state <= FINISHED;
                    end else begin
                        ;
                    end
                    counter <= counter + 1'b1;
                end

                FINISHED: state <= IDLE;
                default: ;
            endcase
        end
    end

endmodule: cacheline_adaptor
