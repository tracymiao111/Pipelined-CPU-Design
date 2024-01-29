module cache_datapath 
import rv32i_types::*;         // import my datatypes
#(
            parameter       s_offset = 5, // fixed
            parameter       s_index  = 4, // parameterized
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index,
            parameter       num_ways = 1 // parameterized
)( 
    input logic clk,
    input logic rst,

    
    input logic [31:0] mem_address,
    input logic [s_mask-1:0] mem_byte_enable256,
    input logic [s_line-1:0]  mem_wdata256,
    output logic [s_line-1:0] mem_rdata256,
    
    input logic [s_line-1:0] pmem_rdata,
    output logic [s_line-1:0] pmem_wdata,
    output logic [31:0] pmem_address,

    // to control
    output logic is_hit,
    // output logic is_valid, // valid_bit_output[#ways]
    output logic is_dirty, // dirty_bit_output[#ways]


    // from control
    input logic is_allocate,
    input logic use_replace,    // is_neg
    input logic load_data,
    input logic load_tag,
    input logic load_dirty,
    input logic load_valid,
    input logic load_plru,
    input logic valid_in,
    input logic dirty_in
);

    // localparam length = $clog2(num_ways);

    /*============================== Signals begin ==============================*/
    // for data array and tag array inputs
    // logic   [255:0] data_d      [4];    // data array, wait why?
    // logic   [22:0]  tag_d       [4];    // tag array, wait why?
    // cacheline_t data_d;
    // tag_word_t tag_d;

    logic [s_line-1:0] data_arr_in;
    logic [s_tag-1:0]  tag_arr_in;  

    // data array and tag array (parameterized ways)
    logic [s_line-1:0]  data_arr_out  [num_ways];     
    logic[s_tag-1:0]   tag_arr_out   [num_ways];     
    
    // plru array (one array for parameterized way)
    // logic [num_ways-2:0]  plru_data_out;
    // logic [num_ways-2:0]  new_plru_data;

    // dirty array and valid array (4 ways)
    logic   valid_out   [num_ways];
    logic   dirty_out   [num_ways];

    logic [num_ways-1:0] hit;            // one hot hit vector
    
    logic[s_tag-1:0] tag_from_addr;   // mem_addr[31:9]
    logic [s_index-1:0] set_idx;        // mem_addr[8:5]      

    logic [$clog2(num_ways)-1:0] hit_way, way_idx, replace_way;
    
    logic[s_tag-1:0] tag_out;         // one of the tags in parameterized ways
    logic[s_line-1:0] data_out;       // one of the data in 4 ways

    logic [s_mask-1:0] write_mask;    // write mask for cacheline
    logic [31:(s_offset + s_index)] final_tag_out;



    // write enable should active low 
    logic [num_ways-1:0] data_web_arr;   // data_web
    logic [num_ways-1:0] tag_web_arr;    // tag_web
    logic [num_ways-1:0] dirty_web_arr;   // chip select for dirty bits
    logic [num_ways-1:0] valid_web_arr;   // chip select for valid bits
    /*============================== Signals end ==============================*/


    /*============================== Assignments begin ==============================*/
    assign tag_from_addr = mem_address[31:(s_offset + s_index)];
    assign tag_arr_in = mem_address[31: (s_offset + s_index)];
    assign set_idx = mem_address[(s_offset + s_index -1):(s_offset)];
    assign pmem_address = {final_tag_out, mem_address[(s_offset + s_index -1):(s_offset)], {(s_offset){1'b0}}};
    // assign is_hit = |hit;            // OR all the hit bit to see if a way is hit

    assign mem_rdata256 = data_out;
    assign pmem_wdata = data_out;
    /*============================== Assignments end ==============================*/
    

    /*============================== Modules begin ==============================*/
    // generate parameterized data_array
    generate for (genvar i = 0; i < num_ways; i++) begin : data_arrays
        mp3_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_web_arr[i]),
            .wmask0     (write_mask),
            .addr0      (set_idx),
            .din0       (data_arr_in),
            .dout0      (data_arr_out[i])
        );
    end endgenerate

    // generate parameterized tag array
    generate for (genvar i = 0; i < num_ways; i++) begin : tag_arrays
        mp3_tag_array tag_array(
            .clk0    (clk),
            .csb0    (1'b0),
            .web0    (tag_web_arr[i]),
            .addr0   (set_idx),
            .din0    (tag_arr_in),
            .dout0   (tag_arr_out[i])
        );
    end endgenerate

    // generate parameterized valid arrays and dirty arrays
    generate for (genvar i = 0; i < num_ways; i++) begin
        ff_array #(.s_index(s_index)) 
        valid_array 
        (
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(valid_web_arr[i]),
            .addr0(set_idx),
            .din0(valid_in),        // data input for all valid array
            .dout0(valid_out[i])    // output
        );
        ff_array #(.s_index(s_index)) 
        dirty_array 
        (  
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(dirty_web_arr[i]),
            .addr0(set_idx),
            .din0(dirty_in),        // data input for all dirty array
            .dout0(dirty_out[i])    // output
        );
    end endgenerate

    // create a plru_array with a width of (num_ways-1) bits
    // ff_array #( .s_index(s_index),
    //             .width(num_ways-1)) 
    // plru_array(
    //     .clk0(clk),
    //     .rst0(rst),
    //     .csb0(1'b0),                 
    //     .web0(~load_plru),           // load_plru will output high from the control, so need to invert it   
    //     .addr0(set_idx),
    //     .din0(new_plru_data),        // new plru bits 
    //     .dout0(plru_data_out)        // output
    // );

    // // we are using correct plru, so we need to have a minimal of 4 ways
    // generate
    //     if(num_ways >= 4) begin
    //         plru_update plru_update(
    //             .hit_way(hit_way),
    //             .plru_bits(plru_data_out),
    //             .new_plru_bits(new_plru_data)
    //         );
    //     end
    //     else begin  
    //         plru_update plru_update(
    //             .hit_way(hit_way),
    //             .new_plru_bits(new_plru_data)
    //         );
    //     end 
    // endgenerate

    // plru_tree #(.ways(num_ways))
    // plru_tree(
    //     .plru_bits(plru_data_out),
    //     .data_o(replace_way)
    // );
    assign replace_way = '0;
    assign is_dirty = dirty_out[replace_way];

    /*============================== Modules end ==============================*/


    /*======================== load data handling begin ========================*/
    always_comb begin 
        data_web_arr = {{(num_ways){1'b1}}};
        tag_web_arr = {{(num_ways){1'b1}}};
        valid_web_arr = {{(num_ways){1'b1}}};
        dirty_web_arr = {{(num_ways){1'b1}}};
        
        unique case(use_replace | (~is_hit)) // determine when to use replace index or hit index
            1'b0: way_idx = hit_way;
            1'b1: way_idx = replace_way;
            default: way_idx = hit_way;
        endcase

        if(load_data == 1'b1) begin 
            data_web_arr[way_idx] = 1'b0;
        end

        if(load_tag == 1'b1) begin
            tag_web_arr[way_idx] = 1'b0;
        end

        if(load_dirty == 1'b1) begin    
            dirty_web_arr[way_idx] = 1'b0;
        end 

        if(load_valid == 1'b1) begin
            valid_web_arr[way_idx] = 1'b0;
        end
    end
    /*======================== load data handling end ========================*/

    /*======================== PLRU begin ========================*/
    // need to be parameterized
    // always_comb begin
    //     // PLRU traverse and updates, this is happen in HIT_CHECK state
    //     // when cache miss, it use the slot here to replace the data
    //     unique case(plru_data_out[0]) // L0
    //         1'b0: begin
    //             unique case(plru_data_out[1])   // L1: decision tree
    //                 1'b0: replace_way = 2'd0;
    //                 1'b1: replace_way = 2'd1;
    //                 default: replace_way = 2'd0;
    //             endcase
    //         end
    //         1'b1: begin
    //             unique case(plru_data_out[2])   // L2: decision tree
    //                 1'b0: replace_way = 2'd2;
    //                 1'b1: replace_way = 2'd3;
    //                 default: replace_way = 2'd2;
    //             endcase
    //         end
    //         default: begin
    //             unique case(plru_data_out[1])   // L1: decision tree
    //                 1'b0: replace_way = 2'd0;
    //                 1'b1: replace_way = 2'd1;
    //                 default: replace_way = 2'd0;
    //             endcase
    //         end
    //     endcase

    //     // use by hit_state, used to update PLRUs
    //     unique case(hit_way[1])
    //         1'd0: new_plru_data = {plru_data_out[2], ~hit_way[0], 1'b1};
    //         1'd1: new_plru_data = {~hit_way[0], plru_data_out[1], 1'b0};
    //         default: new_plru_data = 3'b0;
    //     endcase

    //     // select data from replace way (determined by current PLRU)
    //     // is_valid = valid_out[replace_way];  // extract valid bits
    //     is_dirty = dirty_out[replace_way];  // extract dirty bits
    // end
    /*======================== PLRU end ========================*/
    // 000 --> 1, 011
    // hit 1 x00, x11
    //    L0
    //   /  \
    // L1    L2
    // 12    34

// function void PLRU_Way2();
//     unique case(plru_data_out[0])
//         1'b0: replace_way = 1'b0;
//         1'b1: replace_way = 1'b1;
//         default: replace_way = 1'b0;
//     endcase

//     if (hit_way == '0) begin
//         new_plru_data = 1'b1;
//     end else if (hit_way == 1'b1) begin
//         new_plru_data = 1'b0;
//     end else begin
//         new_plru_data = 1'b0;
//     end

//     is_dirty = dirty_out[replace_way];

// endfunction

// function void PLRU_Way4();
//     unique case (plru_data_out[0])// plru_out [2][1][0]----L2L1L0
//             1'b0:begin
//                 case (plru_data_out[1]) //L1
//                     1'b0: replace_way = 2'b00;
//                     1'b1: replace_way = 2'b01;
//                     default: replace_way = 2'b00;
//                 endcase
//             end 
//             1'b1:begin
//                 case (plru_data_out[2])//L2
//                     1'b0: replace_way = 2'b10;
//                     1'b1: replace_way = 2'b11;
//                     default: replace_way = 2'b10;
//                 endcase
//             end 
//             default: begin
//                 case (plru_data_out[1])
//                     1'b0: replace_way = 2'b00;
//                     1'b1: replace_way = 2'b01;
//                     default: replace_way = 2'b00;
//                 endcase
//             end
//         endcase

//         if (hit_way == '0) begin
//             new_plru_data = {plru_data_out[2], 1'b1, 1'b1};
//         end else if (hit_way == 2'd1) begin
//             new_plru_data = {plru_data_out[2], 1'b0, 1'b1};
//         end else if (hit_way == 2'd2) begin
//             new_plru_data = {1'b1, plru_data_out[1], 1'b0};
//         end else if (hit_way == 2'd3) begin
//             new_plru_data = {1'b0, plru_data_out[1], 1'b0};
//         end else begin
//             new_plru_data = 3'b0; 
//         end

//         is_dirty = dirty_out[replace_way];
// endfunction

// function void PLRU_Way8();
//     unique case (plru_data_out[0])// plru_out [2][1][0]----
//             1'b0:begin
//                 case (plru_data_out[1]) //L1
//                     1'b0: replace_way = plru_data_out[3]? 3'b001:3'b000;
//                     1'b1: replace_way = plru_data_out[4]? 3'b011:3'b010;
//                     default: replace_way = 3'b000;
//                 endcase
//             end 
//             1'b1:begin
//                 case (plru_data_out[2])//L2
//                     1'b0: replace_way = plru_data_out[5]? 3'b101:3'b100;
//                     1'b1: replace_way = plru_data_out[6]? 3'b111:3'b110;
//                     default: replace_way = 3'b100;
//                 endcase
//             end 
//             default: begin
//                 case (plru_data_out[1]) //L1
//                     1'b0: replace_way = plru_data_out[3]? 3'b001:3'b000;
//                     1'b1: replace_way = plru_data_out[4]? 3'b011:3'b010;
//                     default: replace_way = 3'b000;
//                 endcase
//             end
//         endcase

//         if (hit_way == '0) begin
//             {new_plru_data[0], new_plru_data[1], new_plru_data[3]} = 3'b111;
//         end else if (hit_way == 3'd1) begin
//             {new_plru_data[0], new_plru_data[1], new_plru_data[3]} = 3'b110;
//         end else if (hit_way == 3'd2) begin
//             {new_plru_data[0], new_plru_data[1], new_plru_data[4]} = 3'b101;
//         end else if (hit_way == 3'd3) begin
//             {new_plru_data[0], new_plru_data[1], new_plru_data[4]} = 3'b100;
//         end else if (hit_way == 3'd4) begin
//             {new_plru_data[0], new_plru_data[2], new_plru_data[5]} = 3'b011;
//         end else if (hit_way == 3'd5) begin
//             {new_plru_data[0], new_plru_data[2], new_plru_data[5]} = 3'b010;
//         end else if (hit_way == 3'd6) begin
//             {new_plru_data[0], new_plru_data[2], new_plru_data[6]} = 3'b011;
//         end else if (hit_way == 3'd7) begin
//             {new_plru_data[0], new_plru_data[2], new_plru_data[6]} = 3'b010;
//         end else begin
//             new_plru_data = '0; 
//         end

//         is_dirty = dirty_out[replace_way];
// endfunction

//  always_comb begin
//         if (num_ways == 2) begin
//             PLRU_Way2();
//         end else if (num_ways == 4) begin
//             PLRU_Way4();
//         end else if (num_ways == 8) begin
//             PLRU_Way8();
//         end else begin
//             PLRU_Way4();
//         end
//     end
        

    always_comb begin
        is_hit = 1'b0;
        for(int idx = 0; idx < num_ways; idx++) begin
            hit[idx] = 1'(tag_from_addr == tag_arr_out[idx]) & valid_out[idx];
        end 
        is_hit = |hit;            // OR all the hit bit to see if a way is hit
    end
    

    always_comb begin 
        hit_way = '0; 
        // for (int unsigned i = 0; i < num_ways; i++) begin
        //     if (hit[i] == 1'b1) begin
        //         hit_way = i[length-1:0]; 
        //     end
        // end
    end 

    
    //MUXES
    always_comb begin

        // cache selection ord write back data selection  
        tag_out = tag_arr_out[way_idx];
        data_out = data_arr_out[way_idx];

        // mem_byte_enable256 base on current situation
        unique case(is_allocate)
            1'b0: begin
                write_mask = mem_byte_enable256; // write mask
                final_tag_out = tag_out;         // normal tag output from tag arrays
                data_arr_in = mem_wdata256;
            end
            1'b1: begin 
                write_mask = {(s_mask){1'b1}};      // write entire cacheline at allocate
                final_tag_out = tag_from_addr; // using the tag out from mem_addr
                data_arr_in = pmem_rdata;
            end
            default: begin
                write_mask = mem_byte_enable256; // write mask
                final_tag_out = tag_out;         // normal tag output from tag arrays
                data_arr_in = mem_wdata256;
            end
        endcase

    end

endmodule : cache_datapath

