`define CENTER_FREQ 89_700_000
`define CALIB_FREQ 40_679_970
`define CALIB_OFFSET (`CALIB_FREQ - `CENTER_FREQ) // 12_920
`define DEVIATION 2_500
`define BASE_CLK 10_000_000
`define BASE_CLK_MULTIPLY 20
`define BASE_CLK_DIVIDE 1
`define OUTPUT_CLK ((`BASE_CLK*`BASE_CLK_MULTIPLY)/`BASE_CLK_DIVIDE) // 240M
`define REG_SIZE 25

// define PHASE_INC ((CENTER_FREQ -CALIB_OFFSET* (2^REG_SIZE))/OUTPUT_CLK)

// `define PHASE_INC 27'd38_999_865-(1<<`AUDIO_WIDTH)/2 // for 40.68 & 140M
// `define PHASE_INC 27'd22_749_905 // for 40.68 & 240M
// `define PHASE_INC 27'd50_163_876-65535 // for 40.68 & 240M
`define PHASE_INC 25'd15049163-12288 // for 89.7 & 180M
module radio_tx (
    input wire clk10m,
    output reg radio_tx_pin,
    input wire [`REG_SIZE-1:0] inc_value
    // output wire raw_clk
);


wire clk200m_int;
wire clk200m;

DCM_SP #(
    .CLKFX_MULTIPLY(`BASE_CLK_MULTIPLY), 
    .CLKFX_DIVIDE(`BASE_CLK_DIVIDE), 
    .CLKIN_PERIOD(100.0),
    .CLK_FEEDBACK("NONE"),
    .STARTUP_WAIT("FALSE")
) dcm_sp_inst (
    .CLKFX(clk200m_int),
    .CLKIN(clk10m),
    .RST(1'b0),
    .LOCKED(),
    .CLK0(), .CLK2X(), .CLK90(), .CLK180(), .CLK270(),
    .CLKDV(), .CLKFX180(), .STATUS(), .PSCLK(), .PSEN(), .PSINCDEC(), .PSDONE()
);

BUFG bufg_clk200 (.I(clk200m_int), .O(clk200m));

// assign raw_clk = clk200m;

// Synchronizacja audio sample do domeny clk200m

reg [`REG_SIZE-1:0] phase_current_inc = 25'd15049163-12288;
reg [`REG_SIZE-1:0] phase_acc = 0;


always @(posedge clk200m) begin
    phase_current_inc <= inc_value;
    phase_acc <= phase_acc + phase_current_inc;
    radio_tx_pin <= phase_acc[`REG_SIZE-1];
end



endmodule