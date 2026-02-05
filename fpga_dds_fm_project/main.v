`define AUDIO_WIDTH 16
`define CH_WIDTH 16
`define REG_SIZE 25
// `define PHASE_INC 27'd50_163_876-32768 // for 40.68 & 240M
// `define PHASE_INC 27'd40_125_320-32768 // for 40.68 & 240M
`define PHASE_INC 25'd13_681_057 // for 89.7 & 180M


module main (
    input wire clk10m,
    output wire radio_tx_pin,
    input i2s_ws,
    input i2s_sd,
    input i2s_ck

);




wire [`REG_SIZE-1:0] radio_current_sample;


radio_tx radio_tx_inst (
    .clk10m(clk10m),
    .radio_tx_pin(radio_tx_pin),
    .inc_value(radio_current_sample)
);



wire signed [`AUDIO_WIDTH-1:0] left_channel;
wire signed [`AUDIO_WIDTH-1:0] right_channel;


wire data_updated;

i2s i2s_inst (
    .i2s_ck(i2s_ck),
    .i2s_ws(i2s_ws),
    .i2s_sd(i2s_sd),
    .first_channel(left_channel),
    .second_channel(right_channel),
    .data_updated(data_updated)
);

fm_stereo_encoder fm_stereo_encoder_inst (
    .clk10m(clk10m),
    .left_channel(left_channel),
    .right_channel(right_channel),
    .radio_current_sample(radio_current_sample)
);




// always @(posedge i2s_ck) begin
//     if (data_updated) begin
        
//     end
// end




endmodule