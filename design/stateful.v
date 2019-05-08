/**
Demonstration stateful module.

4-bit wide data_in bus and 4-bit wide internal hidden state.
Two strobe lines, one for the upper half of data/state and one for the lower.
Each XORs half of the input into the state.
Output is the state passed through a 4-bit lookup table.

The purpose of this design is to have a meaningful internal state
that we might want to inspect, whose value can't be trivially
determined from the input or output.
*/
module stateful #(
  parameter PERMUTATION = 64'hA91074E6CD382B5F
) (
  input [3:0] data_in,
  input [1:0] strobe,
  output [3:0] data_out,
  input clk);

reg [1:0] last_strobe = 0;

reg [3:0] state = 0;

always @(posedge clk)
begin
  last_strobe <= strobe;

  if (last_strobe[1] && !strobe[1]) begin
    state[3:2] <= state[3:2] ^ data_in[3:2];
  end

  if (last_strobe[0] && !strobe[0]) begin
    state[1:0] <= state[1:0] ^ data_in[1:0];
  end
end

assign data_out = PERMUTATION >> (4 * state);

endmodule
