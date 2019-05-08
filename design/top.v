module top (
  input [3:0] data_async,
  input [1:0] strobe_async,
  output [3:0] data_out,
  output [3:0] extra_gnd,

  input uart_rx,
  output wire uart_tx,

  output USBPU,
  output LED,
  input CLK
);

// Drive USB pull-up resistor to '0' to disable USB.
assign USBPU = 0;

// TinyFPGA-BX blinker.
reg [25:0] blink_counter;
wire [31:0] blink_pattern = 32'b101010001110111011100010101;
always @(posedge CLK) blink_counter <= blink_counter + 1;
assign LED = blink_pattern[blink_counter[25:21]];

// Synchronize inputs to clock.
reg [3:0] data_metastable;
reg [3:0] data_in;
reg [1:0] strobe_metastable;
reg [1:0] strobe;
always @(posedge CLK) begin
  data_metastable <= data_async;
  data_in <= data_metastable;
  strobe_metastable <= strobe_async;
  strobe <= strobe_metastable;
end

// Main logic.
stateful st(
  .data_in(data_in),
  .strobe(strobe),
  .data_out(data_out),
  .clk(CLK));

// Extra ground pins for LEDs.
assign extra_gnd = 0;


// Integrated Logic Analyzer.
wire [15:0] ila_events;

assign ila_events[3:0] = data_in;
assign ila_events[5:4] = strobe;
assign ila_events[9:6] = st.state;
assign ila_events[13:10] = data_out;
assign ila_events[15:14] = 0;

sump2_top s2(
  .clk_in(CLK),
  .uart_wi(uart_rx),
  .uart_ro(uart_tx),
  .events_din(ila_events));


endmodule
