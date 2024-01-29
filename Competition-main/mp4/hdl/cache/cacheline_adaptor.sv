// module cacheline_adaptor
// (
//     input clk,
//     input reset_n,

//     // Port to LLC (Lowest Level Cache)
//     input logic [255:0] line_i,
//     output logic [255:0] line_o,
//     input logic [31:0] address_i,
//     input read_i,
//     input write_i,
//     output logic resp_o,

//     // Port to memory
//     input logic [63:0] burst_i,
//     output logic [63:0] burst_o,
//     output logic [31:0] address_o,
//     output logic read_o,
//     output logic write_o,
//     input resp_i
// );

//     parameter S0 = 3'b000,
//               S1 = 3'b001,
//               S2 = 3'b010,
//               S3 = 3'b011,
//               S4 = 3'b100,
//               S5 = 3'b101;

//     logic [2:0] state, next_state;
//     logic [1:0] counter;
//     logic [255:0] line_temp;
//     logic [31:0] address_temp;
      
//     always_ff @(posedge clk) begin
//         if (~reset_n) begin
//             state <= S0;
//         end else begin
//                 case (state)
//                 S0: begin
//                         address_temp <= address_i;
//                         counter <= '0;
//                         if (read_i) begin
//                                 state <= S1;
//                         end else if (write_i) begin
//                                 state <= S2;
//                                 line_temp <= line_i;
//                         end else begin
//                                 ;
//                         end
//                 end
    
//                 S1: begin
//                     if (resp_i) begin
//                         state <= S3;
//                         counter <= 2'b01;
//                         line_temp[63:0] <= burst_i;
//                     end else begin
//                         ;
//                     end
//                 end
    
//                 S2: begin
//                     if (resp_i) begin
//                         state <= S4;
//                         counter <= 2'b01;
//                     end else begin
//                         ;
//                     end
//                 end
    
//                 S3: begin
//                     if (counter == 2'b11) begin
//                         state <= S5;
//                     end else begin
//                         ;
//                     end
                    
//                         case(counter)
//                                 2'b00: line_temp[63:0] <= burst_i;
//                                 2'b01: line_temp[127:64] <= burst_i;
//                                 2'b10: line_temp[191:128] <= burst_i;
//                                 2'b11: line_temp[255:192] <= burst_i;
//                                 default: line_temp <= '0;  
//                         endcase
//                     counter <= counter + 2'b1;
//                 end
                
//                 S4: begin
//                     if (counter == 2'b11) begin
//                             state <= S5;
//                     end else begin
//                         ;
//                     end
                    
//                     counter <= counter + 2'b1;
//                 end
    
//                 S5: begin
//                         state <= S0;
//                 end 
//                 default: ; 
//             endcase
//         end
//     end

//     always_comb begin
//         line_o = line_temp;
//         address_o = address_temp;
//         case (state)
//                 S1: begin
//                     read_o = 1'b1;
//                     write_o = 1'b0;
//                     resp_o = 1'b0;
//                 end
//                 S2: begin
//                     read_o = 1'b0;
//                     write_o = 1'b1;
//                     resp_o = 1'b0;
//                 end
//                 S4: begin
//                     read_o = 1'b0;
//                     write_o = 1'b1;
//                     resp_o = 1'b0;
//                 end
//                 S3: begin
//                     read_o = 1'b1;
//                     write_o = 1'b0;
//                     resp_o = 1'b0;
//                 end
//                 S5: begin
//                     read_o = 1'b0;
//                     write_o = 1'b0;
//                     resp_o = 1'b1;
//                 end
//                 default: begin
//                         read_o = 1'b0;
//                         write_o = 1'b0;
//                         resp_o = 1'b0;
//                 end
//         endcase

//         case(counter)
//                 2'b00: burst_o = line_temp[63:0];
//                 2'b01: burst_o = line_temp[127:64];
//                 2'b10: burst_o = line_temp[191:128];
//                 2'b11: burst_o = line_temp[255:192];
//         default: burst_o = '0; 
//         endcase

// end
// endmodule : cacheline_adaptor

// module cacheline_adaptor
// #(
//     parameter cacheline_size = 256,
//     parameter burst_size = 64,
//     parameter cycle_count = $clog2(cacheline_size / burst_size) - 1
// )
// (
//     input clk,
//     input reset_n,

//     // Port to LLC (Lowest Level Cache)
//     input logic [cacheline_size-1:0] line_i,
//     output logic [cacheline_size-1:0] line_o,
//     input logic [31:0] address_i,
//     input read_i,
//     input write_i,
//     output logic resp_o,

//     // Port to memory
//     input logic [63:0] burst_i,
//     output logic [63:0] burst_o,
//     output logic [31:0] address_o,
//     output logic read_o,
//     output logic write_o,
//     input resp_i
// );

// logic [cacheline_size-1:0] to_llc_line;  // buffer 
// logic [cycle_count:0] cycle, next_cycle; // counter
// logic [31:0] address_buf;
// logic llc_line_done;  // data ready for LLC
// enum int unsigned {NOT_USE, READ, WRITE, DONE} state, next_state;

// // connections to outputs
// assign line_o = to_llc_line;            // direct connection
// assign address_o = address_buf;           // direct connection
// assign resp_o = llc_line_done;          // resp_o is trigger when, line_pos fill all 256 bits which will be out of bounds in this case
// assign next_cycle = cycle + 1'b1;       // counting up
// assign burst_o = to_llc_line[63:0];     // direct connection for lower bits

// always_comb begin // create a state machine

//     read_o = '0;
//     write_o = '0;            
//     llc_line_done = 1'b0;
//     next_state = state;
//     unique case(state)
//         NOT_USE:
//             if(read_i) next_state = READ;
//             else if(write_i) next_state = WRITE;
//         READ: begin
//             read_o = 1'b1;
//             if(next_cycle == '0) next_state = DONE; // resp_o or llc_line_done, then leave IN_USE
//         end
//         WRITE: begin
//             write_o = 1'b1;
//             if(next_cycle == '0) next_state = DONE; // resp_o or llc_line_done, then leave IN_USE
//         end
//         DONE: begin
//             llc_line_done = 1'b1;
//             next_state = NOT_USE;
//         end
//         default: ;
//     endcase
// end 

// // applied a state machine maybe, can you do it without a state machine
// // non-blocking here
// always_ff @(posedge clk or negedge reset_n) begin
//     if(~reset_n) begin
//         cycle <= '0;
//         address_buf <= address_i;
//         state <= NOT_USE;
//     end 
//     else begin
//         state <= next_state; // keep the state cycle
//         unique case(state) 
//             NOT_USE: begin
//                 address_buf <= address_i;
//                 cycle <= '0;
//                 if(write_i) begin // set up buffer when the write_i is triggered
//                     to_llc_line <= line_i;
//                 end 
//             end
//             READ: begin // reading operation
//                 if(resp_i == 1 && read_o == 1) begin
//                     to_llc_line <= {burst_i, to_llc_line[cacheline_size-1: 64]}; // shift reg, shift in data
//                     cycle <= next_cycle;
//                 end
//             end
//             WRITE: begin // writing operation
//                 if(resp_i == 1 && write_o == 1) begin
//                     to_llc_line <= (to_llc_line >> 64); // shift out data last 64 bits
//                     cycle <= next_cycle;
//                 end 
//             end
//             DONE:;
//             default:;
//         endcase
    
//     end

// end

// endmodule : cacheline_adaptor



module cacheline_adaptor
(
    input                   clk,
    input                   reset_n,

    // All _i and _o here are from the perspective of your cacheline adaptor

    // Port to LLC (Lowest Level Cache)
    input logic [255:0]     line_i,
    output logic [255:0]    line_o,
    input logic [31:0]      address_i,
    input                   read_i,
    input                   write_i,
    output logic            resp_o,

    // Port to memory
    input logic [63:0]      burst_i,
    output logic [63:0]     burst_o,
    output logic [31:0]     address_o,
    output logic            read_o,
    output logic            write_o,
    input                   resp_i
);

    logic [255:0] buffer;
    logic [1:0] counter;
    logic [31:0] address;

    enum logic [2:0] {idle, read_w, write_w, read, write, done} state;

    assign address_o = address;
    assign line_o = buffer;
    assign burst_o = buffer[64*counter +: 64];
    /* https://stackoverflow.com/questions/17778418/what-is-and */
    /* buffer[63 + 64 * counter: 64 * counter] */

    always_comb 
    begin : state_action_comb
    //set default state signals
        resp_o = 1'b0;
        read_o = 1'b0;
        write_o = 1'b0;

        unique case (state)
            idle: ;
            read_w: read_o = 1'b1;
            write_w: write_o = 1'b1;
            read: read_o = 1'b1;
            write: write_o = 1'b1;
            done: resp_o = 1'b1;

            default: ;
        endcase
    end

    always_ff @ (posedge clk)
    begin : state_actions_ff
        if(~reset_n) state <= idle;
        else 
        begin
            unique case (state)
                idle:
                begin
                    address <= address_i;
                    if(read_i) 
                    begin
                        // address <= address_i;
                        state <= read_w;
                        counter <= 2'b0;
                    end
                    else if (write_i) 
                    begin
                        // address <= address_i;
                        buffer <= line_i;
                        state <= write_w;
                        counter <= 2'b0;
                    end
                end
                read_w: 
                begin
                    if(resp_i)
                    begin
                        state <= read;
                        buffer[64*counter +: 64] <= burst_i;
                        counter <= 2'b01;
                    end
                end
                write_w: 
                begin
                    if(resp_i)
                    begin
                        state <= write;
                        counter <= 2'b01;
                    end
                end
                read: 
                begin
                    if(counter == 2'b11) state <= done;
                    buffer[64*counter +: 64] <= burst_i;
                    counter <= counter + 2'b01;
                end
                write:
                begin
                    if(counter == 2'b11) state <= done;
                    counter <= counter + 2'b01;
                end 

                done: state <= idle;
                default: ;
            endcase
        end
    end

    

endmodule : cacheline_adaptor
