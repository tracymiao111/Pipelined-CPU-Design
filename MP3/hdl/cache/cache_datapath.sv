module cache_datapath #(
            parameter                     s_offset = 5,
            parameter                     s_index  = 4,
            parameter                     s_tag    = 32 - s_offset - s_index,
            parameter                     s_mask   = 2**s_offset,
            parameter                     s_line   = 8*s_mask,
            parameter                     num_sets = 2**s_index
)(
    input   logic                         clk,
    input   logic                         rst,
    /******************* with CPU ***********************/
    input   logic      [31:0]             mem_address,
    input   logic      [31:0]             mem_byte_enable256,
    input   logic      [s_line - 1 : 0]   mem_wdata256,
    output  logic      [s_line - 1 : 0]   mem_rdata256,
    /******************* with MEM ***********************/
    input   logic      [s_line - 1 : 0]   pmem_rdata,
    output  logic      [s_line - 1 : 0]   pmem_wdata,
    output  logic      [31:0]             pmem_address,
    /***************** with CONTROL **********************/
    input   logic                         allo_sig,
    input   logic                         rep_sig,
    input   logic                         load_data,
    input   logic                         load_tag,
    input   logic                         load_valid,
    input   logic                         load_dirty,
    input   logic                         load_plru,
    input   logic                         valid_i,
    input   logic                         dirty_i,
    output  logic                         hit_sig,
    output  logic                         dirty_sig
);
            localparam                     num_ways = 4;
            localparam                     way_bits  = $clog2(num_ways) - 1;
            logic      [s_index  - 1 : 0]  idx;
            logic      [way_bits     : 0]  rep_idx, hit_idx;
            logic      [num_ways - 1 : 0]  hit_way;
            logic      [s_line   - 1 : 0]  cache_out;
            logic      [way_bits     : 0]  way_idx;

    /***************** for data_array ********************/
            logic      [s_line   - 1 : 0]  data_i;
            logic      [s_line   - 1 : 0]  data_o[num_ways];
            logic      [num_ways - 1 : 0]  data_web ;
            logic      [s_mask   - 1 : 0]  data_mask;

    /***************** for tag_array *********************/
            logic      [s_tag    - 1 : 0]  tag_i;
            logic      [s_tag    - 1 : 0]  tag_o[num_ways];
            logic      [num_ways - 1 : 0]  tag_web;  
            logic      [s_tag    - 1 : 0]  tag_out; 

    /*********** for valid, dirty & plru array ************/            
            logic                          valid_o[num_ways];
            logic      [num_ways - 1 : 0]  valid_web;
            logic                          dirty_o[num_ways];
            logic      [num_ways - 1 : 0]  dirty_web;
            logic      [num_ways - 2 : 0]  plru_i, plru_o;
            logic                          plru_web;



    function void initialization1();
        data_web  = {{(num_ways){1'b1}}};
        tag_web   = {{(num_ways){1'b1}}};
        valid_web = {{(num_ways){1'b1}}};
        dirty_web = {{(num_ways){1'b1}}};
        plru_web  = 1'b1;
    endfunction 

    function void initialization2();
        way_idx = 2'b0;
        hit_sig = 1'b0;
        hit_idx = 2'b0;    
    endfunction   

    always_comb begin
        initialization1();
        tag_i              = mem_address[31:(s_offset + s_index)]; 
        idx                = mem_address[(s_offset + s_index - 1) : (s_offset)];
        dirty_sig          = dirty_o    [rep_idx];
        data_web [way_idx] = load_data  ? 1'b0 : 1'b1; //low active
        tag_web  [way_idx] = load_tag   ? 1'b0 : 1'b1; //low active
        valid_web[way_idx] = load_valid ? 1'b0 : 1'b1; //low active
        dirty_web[way_idx] = load_dirty ? 1'b0 : 1'b1; //low active
        plru_web           = load_plru  ? 1'b0 : 1'b1; //low active 
    end

    genvar i;
    generate for (i = 0; i < num_ways; i++) begin : arrays
        mp3_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_web[i]),
            .wmask0     (data_mask),
            .addr0      (idx),
            .din0       (data_i),
            .dout0      (data_o[i])
        );

        mp3_tag_array tag_array(
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (tag_web[i]),
            .addr0      (idx),
            .din0       (tag_i),
            .dout0      (tag_o[i])
        );

        ff_array #(.s_index(s_index)) valid_array(
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (valid_web[i]),
            .addr0      (idx),
            .din0       (valid_i),       
            .dout0      (valid_o[i])
        );

        ff_array #(.s_index(s_index)) dirty_array(
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (dirty_web[i]),
            .addr0      (idx),
            .din0       (dirty_i),       
            .dout0      (dirty_o[i])
        );
    end endgenerate

    ff_array #(.s_index(s_index),
               .width(num_ways - 1)) plru_array(
    .clk0       (clk),
    .rst0       (rst),
    .csb0       (1'b0),
    .web0       (plru_web),
    .addr0      (idx),
    .din0       (plru_i),       
    .dout0      (plru_o)
   );

    /************* plru update logic *****************/
    always_comb begin
        unique case (plru_o[0])
            1'b0:    rep_idx = plru_o[1] ? 2'b01 : 2'b00;
            1'b1:    rep_idx = plru_o[2] ? 2'b11 : 2'b10;
            default: rep_idx = plru_o[1] ? 2'b01 : 2'b00;
        endcase


        unique case (hit_way)
            4'd0:    plru_i = {plru_o[2], 1'b1, 1'b1};
            4'd1:    plru_i = {plru_o[2], 1'b0, 1'b1};
            4'd2:    plru_i = {1'b1, plru_o[1], 1'b0};
            4'd3:    plru_i = {1'b0, plru_o[1], 1'b0};
            default: plru_i = 3'b0;
        endcase
    end

    always_comb begin
        initialization2();
        for (int i = 0; i < num_ways; i++) begin
            hit_way[i] = valid_o[i] && (mem_address[31:9] == tag_o[i]); 
            if (hit_way[i]) hit_idx = i[1:0]; 
        end

        hit_sig   = |hit_way;  
        way_idx   = (rep_sig | (~hit_sig))? rep_idx : hit_idx;
        cache_out = data_o[way_idx];

        if (allo_sig) begin
            data_mask = 32'hFFFFFFFF;
            data_i    = pmem_rdata;
            tag_out   = mem_address[31:9];
        end else begin
            data_mask = mem_byte_enable256;
            data_i    = mem_wdata256;
            tag_out   = tag_o[way_idx];
        end
    end

    assign mem_rdata256 = cache_out;
    assign pmem_wdata   = cache_out;
    assign pmem_address = {tag_out, idx, {s_offset{1'b0}}};

endmodule : cache_datapath