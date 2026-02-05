
`define CENTER_FREQ 40_680_000
`define REG_SIZE 27
`define OUTPUT_CLK 140_000_000

module test;
  initial begin
    $display("CENTER_FREQ = %d", `CENTER_FREQ);
    $display("2^REG_SIZE = %d", 2**`REG_SIZE);  
    $display("Product = %d", `CENTER_FREQ * (2**`REG_SIZE));
    $display("PHASE_INC = %d", (`CENTER_FREQ * (2**`REG_SIZE))/`OUTPUT_CLK);
    $display("Expected = %d", 39012295);
  end
endmodule

