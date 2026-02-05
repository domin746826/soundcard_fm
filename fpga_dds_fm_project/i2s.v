// `timescale 1us / 100ns

`define CH_WIDTH 16


module i2s (
    input wire i2s_ck,
    input wire i2s_ws,
    input wire i2s_sd,
    output reg signed [`CH_WIDTH-1:0] first_channel = 0,
    output reg signed [`CH_WIDTH-1:0] second_channel = 0,
    output reg data_updated = 1'b0 
);



reg last_ws = 1'b1;

reg [5:0] bit_num = 0; // 32 bits for whole frame
reg [`CH_WIDTH*2-1:0] frame = 0;

always @(posedge i2s_ck) begin
    if(i2s_ws == 1 && last_ws == 0) begin
        first_channel <= frame[`CH_WIDTH*2-1:`CH_WIDTH];
        second_channel <= frame[`CH_WIDTH-1:0];
        data_updated <= 1'b1;
        bit_num <= 30; // in next cycle we will read second bit, in PHILIPS mode it would be 0
        frame[31] <= i2s_sd;

    end else begin
        bit_num <= bit_num - 1;
        data_updated <= 1'b0;
        frame[bit_num] <= i2s_sd;

    end

    last_ws <= i2s_ws;
end
    



endmodule

