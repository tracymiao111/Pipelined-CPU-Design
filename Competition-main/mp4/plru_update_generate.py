import math

# with plru, num_ways need to be a power of 2, only change this
num_ways = 2




plru_len = num_ways - 1
replace_data_width = int(math.log2(num_ways))

mask_array = [["0" for _ in range(num_ways-1)] for _ in range(num_ways)] 

for i in range(num_ways):
    i_bin_str = format(i & num_ways-1, f'0{replace_data_width}b')  
    # i_bin_str = i_bin_str[::-1] # reverse string, no reversing for sv
    start = 0
    for j in range(0, replace_data_width, 1): # determine what bit needs to be flipped
        mask_array[i][start] = '1'
        if i_bin_str[j] == '1':
            start = start * 2 + 2
        else:
            start = start * 2 + 1

module_begin_string = f"""
module plru_update(  
    input logic [{replace_data_width-1} : 0] hit_way,
    input logic [{plru_len-1} : 0] plru_bits,
    output logic [{plru_len-1} : 0] new_plru_bits
);
"""

if (num_ways < 4):
    module_begin_string =f"""
module plru_update(  
    input logic [{replace_data_width-1} : 0] hit_way,
    output logic [{plru_len-1} : 0] new_plru_bits
);
"""


module_end_string = "endmodule\n"

plru_update_sv_path = "hdl/cache/dcache/plru_update.sv"
plru_update_sv_file = open(plru_update_sv_path, "w")
plru_update_sv_file.write(module_begin_string)
plru_update_sv_file.write(""" 
always_comb begin
    case(hit_way)
""")

# generate all the case
for i in range(num_ways):
    temp_write = []
    hit_way_idx = replace_data_width - 1
    for j in range(len(mask_array[0])):
        if mask_array[i][j] == '1':
            temp_write.insert(0, f"~hit_way[{hit_way_idx}]")
            hit_way_idx -= 1
        else:
            temp_write.insert(0, f"plru_bits[{j}]")
    
    write_string = '{' + ', '.join(temp_write)+ '}'


    # plru_update_sv_file.write(f"        {replace_data_width}'d{i}: new_plru_bits = plru_bits ^ {plru_len}'b{''.join(mask_array[i][::-1])};\n")
    plru_update_sv_file.write(f"        {replace_data_width}'d{i}: new_plru_bits = {write_string};\n")

    
plru_update_sv_file.write(f"""
        default: new_plru_bits = {plru_len}'b{''.join(['0' for _ in range(plru_len)])};
    endcase
end
""")

plru_update_sv_file.write(module_end_string)
plru_update_sv_file.close()
