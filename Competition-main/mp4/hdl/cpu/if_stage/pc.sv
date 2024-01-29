module pc (
    input clk,
    input rst,
    input load,
    input logic [31:0] in,
    output logic [31:0] out
);
logic [31:0] temp;
always_ff @(posedge clk)
begin
    if (rst == 1'b1) begin
        temp <= 32'h40000000;
    end
    else if(load == 1'b1) begin
        temp <= in;
    end
    else begin
        temp <= temp;
    end
end
assign out = temp;

endmodule: pc