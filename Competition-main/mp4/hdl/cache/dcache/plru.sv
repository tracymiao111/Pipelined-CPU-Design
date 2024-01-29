// module mux_2_to_1 #(
//     parameter width = 2 // 4 ways by default
// )(
//     input   logic [width - 1: 0] data_zero_i,
//     input   logic [width - 1: 0] data_one_i,
//     input   logic data_sel_i,
//     output  logic [width - 1: 0] data_o
// );

// // simple selection
// assign data_o = data_sel_i ? data_one_i : data_zero_i;

// endmodule


// module plru_tree #(
//     parameter ways = 4,
//     parameter data_width = $clog2(ways),
//     parameter plru_bits_len = ways - 1
// )(
//     input logic  [plru_bits_len-1: 0]  plru_bits,//change
//     output logic [data_width - 1: 0] data_o
// );

// parameter data_array_len = (ways << 1) - 1;
// parameter second_last_layer = data_array_len - 2 ** (data_width);

// // perfect tree structure array
// logic [data_width - 1 : 0] data_array [data_array_len];

// // generation loop
// generate
//     genvar i;
//     for(i = 0; i < second_last_layer; i++) begin
//         mux_2_to_1 #(.width(data_width))
//         mux2to1(
//             .data_zero_i(data_array[(i*2) + 1]),
//             .data_one_i(data_array[(i*2) + 2]),
//             .data_sel_i(plru_bits[i]),
//             .data_o(data_array[i])
//         );
//     end
// endgenerate
// always_comb begin
// // logic assignment loop
//     for(int j = 0; j < data_array_len - second_last_layer; ++j) begin
//         data_array[j+second_last_layer] = j[data_width - 1 : 0];
//     end
// end
// // logic [$clog2(data_array_len + 1): 0] j;
// // always_comb begin
// //     for(j = '0; j < data_array_len - second_last_layer; ++j) begin
// //         assign data_array[j + second_last_layer] = j[data_width - 1 : 0];
// //     end
// // end

// // the root is the output
// assign data_o = data_array[0];

// endmodule

// // module mux_2_to_1(
// //     parameter data_width = 2 // 4 ways by default
// // )(
// //     input   logic [data_width - 1: 0] data_zero_i,
// //     input   logic [data_width - 1: 0] data_one_i,
// //     input   logic data_sel_i,
// //     output  logic [data_width - 1: 0] data_o
// // );

// // // simple selection
// // assign data_o = data_sel_i ? data_one_i : data_zero_i;

// // endmodule


// // module plru_tree(
// //     parameter ways = 4,
// //     parameter data_width = $clog2(ways),
// //     parameter plru_bits_len = ways - 1
// // )(
// //     input logic  [plru_bits_len -1 : 0]  plru_bits,
// //     output logic [data_width - 1: 0] data_o
// // );

// // parameter data_array_len = (ways << 1) - 1;
// // parameter second_last_layer = data_array_len - 2 ** (data_width);

// // // perfect tree structure array
// // logic [data_width - 1 : 0] data_array [data_array_len];

// // // generation loop
// // generate
// //     genvar i;
// //     for(i = 0; i < second_last_layer; i++) begin
// //         mux_2_to_1 mux2to1(
// //             .data_zero_i(data_array[(i*2) + 1]),
// //             .data_one_i(data_array[(i*2) + 2]),
// //             .data_sel_i(plru_bits[i]),
// //             .data_o(data_array[i]),
// //         );
// //     end
// // endgenerate

// // // logic assignment loop
// // for(logic[$clog2(data_array_len + 1): 0] j = 0; j < data_array_len - second_last_layer; ++j) begin
// //     assign data_array[j + second_last_layer] = j[data_width - 1 : 0];
// // end

// // // the root is the output
// // assign data_o = data_array[0];

// // endmodule



/********new github grab version ******/
module mux_2_to_1 #(
    parameter data_width = 3
)(
    input   logic [data_width - 1: 0] data_zero_i,
    input   logic [data_width - 1: 0] data_one_i,
    input   logic data_sel_i,
    output  logic [data_width - 1: 0] data_o
);

// simple selection
assign data_o = data_sel_i ? data_one_i : data_zero_i;

endmodule


module plru_tree #(
    parameter ways = 8,
    parameter data_width = $clog2(ways),
    parameter plru_bits_len = ways - 1
)(
    input logic  [plru_bits_len -1 : 0]  plru_bits,
    output logic [data_width - 1: 0] data_o
);

localparam data_array_len = (ways << 1) - 1;
localparam second_last_layer = data_array_len - 2 ** (data_width);
localparam data_index_len = $clog2(ways << 1);

// perfect tree structure array
logic [data_width - 1 : 0] data_array [data_array_len];

// generation loop
generate
    genvar i;
    for(i = 0; i < second_last_layer; i++) begin
        mux_2_to_1 #(.data_width(data_width))
        mux2to1(
            .data_zero_i(data_array[(i*2) + 1]),
            .data_one_i(data_array[(i*2) + 2]),
            .data_sel_i(plru_bits[i]),
            .data_o(data_array[i])
        );
    end
endgenerate

// logic assignment loop
generate
    for(genvar j = 0; j < data_array_len - second_last_layer; ++j) begin
        assign data_array[j + second_last_layer] = j[data_width - 1 : 0];
    end
endgenerate

// the root is the output
assign data_o = data_array[0];

endmodule


