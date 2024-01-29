module l2_cache_datapath 
import rv32i_types::*;         // import my datatypes
#(
            parameter       s_offset = 5,                   // cacheline size, 5 bit = 32, 32 * 8 = 256; 4 bit = 16, 16 * 8 = 128
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index,
            parameter       num_ways = 2
)( 
    input logic clk,
    input logic rst,
    input logic[s_mask-1:0] mem_byte_enable256,
    input logic [31:0] mem_address,
    input [s_line-1:0]  mem_wdata256,
    output [s_line-1:0] mem_rdata256,
    
    input [s_line-1:0] pmem_rdata,
    output [s_line-1:0] pmem_wdata,
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
    localparam length = $clog2(num_ways);

    /*============================== Signals begin ==============================*/
    // for data array and tag array inputs
    // logic   [255:0] data_d      [4];    // data array, wait why?
    // logic   [22:0]  tag_d       [4];    // tag array, wait why?
    // cacheline_t data_d;
    // logic[s_tag-1:0] tag_d;

    logic[s_line-1:0] data_arr_in;
    logic[s_tag-1:0]  tag_arr_in;  

    // data array and tag array (4 ways)
    logic[s_line-1:0]  data_arr_out  [num_ways];     // data_out from 4 ways
    logic[s_tag-1:0]   tag_arr_out   [num_ways];     // tag_out from 4 ways
    
    // plru array (one array for 4 way)
    logic [num_ways-2:0]  plru_data_out;
    logic [num_ways-2:0]  new_plru_data;

    // dirty array and valid array (4 ways)
    logic   valid_out   [num_ways];
    logic   dirty_out   [num_ways];

    logic [num_ways-1:0] hit;            // one hot hit vector
    
    logic[s_tag-1:0] tag_from_addr;   // mem_addr[31:9]
    logic [3:0] set_idx;        // mem_addr[8:5]      

    logic [$clog2(num_ways)-1:0] hit_way, way_idx, replace_way;
    
    logic[s_tag-1:0] tag_out;         // one of the tags in 4 ways
    logic[s_line-1:0] data_out;       // one of the data in 4 ways

    logic [s_mask-1:0] write_mask;    // write mask for cacheline
    logic[s_tag-1:0] final_tag_out;


    // write enable should active low 
    logic [num_ways-1:0] data_web_arr;   // data_web
    logic [num_ways-1:0] tag_web_arr;    // tag_web
    logic [num_ways-1:0] dirty_web_arr;   // chip select for dirty bits
    logic [num_ways-1:0] valid_web_arr;   // chip select for valid bits
    /*============================== Signals end ==============================*/


    /*============================== Assignments begin ==============================*/
    assign tag_from_addr = mem_address[31: (31-s_tag + 1)];
    assign tag_arr_in = mem_address[31: (31-s_tag + 1)];
    assign set_idx = mem_address[(31-s_tag): s_offset];
    assign pmem_address = {final_tag_out, mem_address[(31-s_tag): s_offset], {(s_offset){1'b0}}};
    // assign is_hit = |hit;            // OR all the hit bit to see if a way is hit

    assign mem_rdata256 = data_out;
    assign pmem_wdata = data_out;

    /*======mem_byte_enable======================== Assignments end ==============================*/
    

    /*============================== Modules begin ==============================*/
    // generate 4 data_array
    generate for (genvar i = 0; i < num_ways; i++) begin : data_arrays
        L2_data_array l2_data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_web_arr[i]),
            .wmask0     (write_mask),
            .addr0      (set_idx),
            .din0       (data_arr_in),
            .dout0      (data_arr_out[i])
        );
    end endgenerate

    // generate 4 tag array
    generate for (genvar i = 0; i < num_ways; i++) begin : tag_arrays
        L2_tag_array l2_tag_array(
            .clk0    (clk),
            .csb0    (1'b0),
            .web0    (tag_web_arr[i]),
            .addr0   (set_idx),
            .din0    (tag_arr_in),
            .dout0   (tag_arr_out[i])
        );
    end endgenerate

    // generate 4 valid arrays and 4 dirty arrays
    generate for (genvar i = 0; i < num_ways; i++) begin
        ff_array l2_valid_array (
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(valid_web_arr[i]),
            .addr0(set_idx),
            .din0(valid_in),        // data input for all valid array
            .dout0(valid_out[i])    // output
        );
        ff_array l2_dirty_array (  
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(dirty_web_arr[i]),
            .addr0(set_idx),
            .din0(dirty_in),        // data input for all dirty array
            .dout0(dirty_out[i])    // output
        );
    end endgenerate

    // create a plru_array with a width of 3 bits
    ff_array #(.width(num_ways-1)) l2_plru_array(
        .clk0(clk),
        .rst0(rst),
        .csb0(1'b0),                 
        .web0(~load_plru),           // load_plru will output high from the control, so need to invert it   
        .addr0(set_idx),
        .din0(new_plru_data),        // new plru bits 
        .dout0(plru_data_out)        // output
    );

    plru_update l2_plru_update(
        .hit_way(hit_way),
        // .plru_bits(plru_data_out),
        .new_plru_bits(new_plru_data)
    );

    plru_tree #(.ways(num_ways))
    plru_tree(
        .plru_bits(plru_data_out),
        .data_o(replace_way)
    );

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

    // /*======================== PLRU begin ========================*/
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

    always_comb begin
        is_hit = 1'b0;
        for(int idx = 0; idx < num_ways; idx++) begin
            hit[idx] = 1'(tag_from_addr == tag_arr_out[idx]) & valid_out[idx];
        end 
        is_hit = |hit;            // OR all the hit bit to see if a way is hit
    end


    always_comb begin 
        hit_way = '0; 
        for (int unsigned i = 0; i < num_ways; i++) begin
            if (hit[i] == 1'b1) begin
                hit_way = i[length-1:0]; 
            end
        end
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

endmodule : l2_cache_datapath
