`timescale 1 ns / 100 ps

module tb();

reg [3:0] data_in = 0;
reg [1:0] strobe = 0;
wire [3:0] data_out;

reg clk = 0;
always #10 clk <= ~clk;

stateful st(
  .data_in(data_in),
  .strobe(strobe),
  .data_out(data_out),
  .clk(clk));

initial
begin
  $dumpfile("out.vcd");
  $dumpvars;
  @(posedge clk);

  #5;

  #20 strobe[0] <= 1;
  #20 strobe[0] <= 0;

  #20 data_in[1:0] <= 2'b01;
  #20 strobe[0] <= 1;
  #20 strobe[0] <= 0;


  #20 data_in[1:0] <= 2'b11;
  #20 data_in[3:2] <= 2'b11;
  #20 strobe[0] <= 1;
  #20 strobe[0] <= 0;

  #20 strobe[1] <= 1;
  #20 strobe[1] <= 0;

  #20 data_in[3:2] <= 2'b01;
  #20 strobe[1] <= 1;
  #20 strobe[1] <= 0;

  #30;

  $finish;
end

endmodule
